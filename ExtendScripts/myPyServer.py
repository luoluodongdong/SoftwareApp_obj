#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 2017/11/25 20:37
import socket
import threading
import select
import time

class MySocketServer(object):
    """docstring for MySocketServer"""
    def __init__(self, ip='127.0.0.1',port=8002):
        super(MySocketServer, self).__init__()
        self.ip = ip
        self.port=port
        self.socket= socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.socket.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)


    def start(self):
        self.socket.bind((self.ip,self.port))
        self.socket.listen(5)
        while True:
            r, w, e = select.select([self.socket,],[],[],1)
            print('looping:wait client connect...')
            if self.socket in r:
                print('get request')
                request, client_address = self.socket.accept()
                t = threading.Thread(target=self.process,args=(request,client_address))
                t.daemon = False
                t.start()
                break
        print("a client connected")

        

    def process(self,request, client_address):
        print(request,client_address)
        conn = request
        ack='connect socket server ok'.encode('utf-8')
        conn.sendall(bytes(ack))
        time.sleep(0.2)
        Flag = True
        while Flag:
            data = conn.recv(1024)
            #data = str(data, encoding='utf8')
            data = data.decode('utf-8')
            if len(data) < 1:
                continue
            print('[RX]'+str(len(data)) +data)
            response='NA'
            if data.upper() == 'EXIT':
                Flag = False
                response='exit OK'
            else:
                response=self.execute_test(data)
            print('[TX]'+response)
            response=response.encode('utf-8')
            conn.sendall(bytes(response))
        conn.shutdown(2)
        conn.close()
        self.socket.close()
        print('shutdown')

    def execute_test(self,cmd):
        response="error command"
        if cmd.upper() == 'READY':
            response=cmd + ' OK'
        else:
            response= 'bad command'

        return response


def main():
    myServer=MySocketServer("127.0.0.1",8002)
    myServer.start()

if __name__ == '__main__':
    main()
