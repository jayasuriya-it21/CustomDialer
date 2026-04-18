package com.phone.dialer.telecom

import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.PhoneAccountHandle

class PhoneConnectionService : ConnectionService() {
    
    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        val connection = PhoneConnection()
        connection.setInitializing()
        return connection
    }

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        val connection = PhoneConnection()
        connection.setInitializing()
        return connection
    }
}

class PhoneConnection : Connection() {
    override fun onAnswer() {
        super.onAnswer()
        setActive()
    }

    override fun onReject() {
        super.onReject()
        setDisconnected(android.telecom.DisconnectCause(android.telecom.DisconnectCause.REJECTED))
        destroy()
    }

    override fun onDisconnect() {
        super.onDisconnect()
        setDisconnected(android.telecom.DisconnectCause(android.telecom.DisconnectCause.LOCAL))
        destroy()
    }
}
