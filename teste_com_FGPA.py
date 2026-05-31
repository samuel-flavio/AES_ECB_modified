import serial
import time

ser = serial.Serial('COM9', 115200, timeout=3)
time.sleep(2)

# Envia 16 vezes o caractere 'A' (Hex 0x41)
msg = b'ABCDEFGHIJKLMNOP' 
ser.write(msg)

# Deve receber 16 vezes o caractere 'B' (Hex 0x42)
resposta = ser.read(16)
print(f"Enviado: {msg}")
print(f"Recebido: {resposta}")
ser.close()