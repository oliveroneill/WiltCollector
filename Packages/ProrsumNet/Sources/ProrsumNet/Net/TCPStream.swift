//
//  TCPClient.swift
//  Prorsum
//
//  Created by Yuki Takei on 2016/12/03.
//
//

public class TCPStream: DuplexStream {
    
    let socket: TCPSocket
    
    public var isClosed: Bool {
        return socket.isClosed
    }
    
    private var address: Address?
    
    public init(socket: TCPSocket) {
        self.socket = socket
    }
    
    public convenience init() throws {
        try self.init(socket: TCPSocket())
        try socket.setBlocking(shouldBlock: true)
    }
    
    public convenience init(host: String, port: UInt) throws {
        try self.init()
        self.address = Address(host: host, port: port)
    }
    
    public func open(deadline: Double = 0) throws {
        guard let address = self.address else {
            throw StreamError.couldNotOpen
        }
        try self.socket.connect(host: address.host, port: address.port)
    }
    
    public func read(upTo numOfBytes: Int = 1024, deadline: Double = 0) throws -> Bytes {
        return try socket.recv(upTo: numOfBytes, deadline: deadline)
    }
    
    public func write(_ bytes: Bytes, deadline: Double = 0) throws {
        return try socket.send(bytes, deadline: deadline)
    }
    
    public func close() {
        socket.close()
    }
    
}
