import termios, tty, os, select, re, sys, signal
signal.signal(signal.SIGTTOU, signal.SIG_IGN)
signal.signal(signal.SIGTTIN, signal.SIG_IGN)
try:
    fd = os.open('/dev/tty', os.O_RDWR)
except OSError:
    sys.exit(1)
attrs = termios.tcgetattr(fd)
tty.setraw(fd)
qs = b''.join(f'\x1b]4;{i};?\x07'.encode() for i in range(16))
os.write(fd, qs)
resp = b''
r,_,_ = select.select([fd],[],[],0.5)
if r:
    while True:
        r2,_,_ = select.select([fd],[],[],0.15)
        if not r2: break
        b = os.read(fd, 4096)
        if not b: break
        resp += b
termios.tcsetattr(fd, termios.TCSADRAIN, attrs)
os.close(fd)
colors = {}
for m in re.finditer(r'\x1b\]4;(\d+);rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+)', resp.decode(errors='replace')):
    i = int(m.group(1))
    r = int(m.group(2), 16) // 257
    g = int(m.group(3), 16) // 257
    b = int(m.group(4), 16) // 257
    sys.stdout.write(f'{i}=#{r:02x}{g:02x}{b:02x}\n')
if len(colors) < 16:
    sys.exit(1)
