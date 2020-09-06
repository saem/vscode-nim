import jsffi
import jscore
import jsconsole

import jsNode
import jsNodeNet
import jsNodeUtil
import jsNodeCp
import jsString
import jsPromise

import strformat
import nimsuggest/sexp

type
    EPCPeer* = ref object
        socket:NetSocket
        receivedBuffer:Buffer
        sessions:Map[cint, proc(data:seq[SExpNode]):void]
        socketClosed:bool

proc envelop(content:cstring):cstring =
    return ("000000" & util.newTextEncoder().encode(content).len.toString(16))[^6..^1] & content

proc generateUid():cint =
    return cint(Math.floor(Math.random() * 10000))

proc newEPCPeer(socket:NetSocket):EPCPeer =
    var epc = EPCPeer(
        socket:socket,
        receivedBuffer:newBuffer(0),
        sessions:newMap[cint, proc(d:seq[SExpNode])](),
        socketClosed:false)

    epc.socket.onData(proc(data:Buffer) =
        epc.receivedBuffer = bufferConcat(@[epc.receivedBuffer, data])
        while epc.receivedBuffer.len > 0:
            if epc.receivedBuffer.len >= 6:
                var length = parseCint(epc.receivedBuffer.toStringUtf8(0, 6), 16)
                if epc.receivedBuffer.len >= (length + 6):
                    var content = parseSexp($(epc.receivedBuffer.toStringUtf8(6, 6 + length)))
                    if content.toJs().to(bool):
                        var contentSexp:seq[SExpNode] = content.getElems()
                        var guid = cint(contentSexp[1].getNum())
                        var handle = epc.sessions.get(guid)
                        handle(contentSexp)
                        epc.sessions.delete(guid)
                    else:
                        for session in epc.sessions.values():
                            session("Received invalid SExp data".toJs().to(seq[SexpNode]))
                    
                    epc.receivedBuffer = epc.receivedBuffer.slice(6 + length)
                else:
                    return
        epc.socket.onClose(proc(error:bool) =
            console.error("Connection close" & (if error: " due to an error" else: ""))
            for session in epc.sessions.values():
                session("Connection closed".toJs().to(seq[SexpNode]))
            epc.socketClosed = true
        )
    )

    return epc

proc callMethod*(epc:EPCPeer, meth:cstring, params:seq[SExpNode]):Promise[seq[SExpNode]] =
    return newPromise(proc(
            resolve:proc(data:seq[SExpNode]),
            reject:proc(reason:JsObject)
        ) =
            if epc.socketClosed:
                reject("Connection closed".toJs())
            
            var guid = generateUid()
            var payload = fmt"(call {guid} {meth} {$(sexp(params))})"
            epc.sessions.set(guid, proc(data:seq[SExpNode]) =
                if not data.toJs().isJsArray():
                    reject(data.toJs())
                else:
                    case (data[0].getSymbol())
                    of "return": resolve(data[2].getElems())
                    of "return-error", "epc-error": reject(data[2].toJs())
                    else: console.error("Unknown error handling sexp")
            )
            epc.socket.write(envelop(payload))
    )

proc stop*(epc:EPCPeer):void =
    if not epc.socketClosed:
        epc.socket.destroy()

proc startClient*(port:cint):Promise[EPCPeer] =
    return newPromise(proc(resolve:proc(e:EPCPeer), reject:proc(reason:JsObject)) =
        try:
            var socket:NetSocket
            socket = net.createConnection(port, "localhost", proc() =
                resolve(newEPCPeer(socket))
            )
        except:
            reject(getCurrentException().toJs())
    )