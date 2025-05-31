import socket
import threading

HOST = "0.0.0.0"  # Standard loopback interface address (localhost)
PORT = 8001 # Port to listen on (non-privileged ports are > 1023)
shared_fname = "/root/nfs/tmp/saw-shared.file"

def on_conn(conn):
    with conn:
        data = conn.recv(1024) # Expect: REQ
        if not data:
            return
        if b"REQ" not in data:
            conn.send(b"INVAL")
            return
        try:
            f = open(shared_fname, 'rb')
            with f:
                data = f.read(1024)
                while data:
                    conn.send(data)
                    data = f.read(1024)
        except Exception as e:
            conn.send(b"INVAL")
            print("exception: ", e)
        print("Done sending")


with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen()
    print("Sharing {} at {}:{}".format(shared_fname, HOST, PORT))
    while True:
        conn, addr = s.accept()
        print(f"Connected by {addr}, forking thread")
        thread = threading.Thread(target=on_conn, args=(conn,))
        thread.start()
