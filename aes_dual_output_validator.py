import serial
import time
import csv
from Crypto.Cipher import AES

# --- Configurações de Hardware ---
SERIAL_PORT = 'COM9'  # Ajuste para a porta da sua Basys 3
BAUD_RATE = 921600    
SECRET_KEY = bytes.fromhex('0f1571c947d9e8590cb7add6af7f6798')

# --- Nomes dos Arquivos ---
# Imagens disponíveis: 'CisnePretoBranco.bin', 'FrutaPadraoConstanteCor.bin', 'vistaAereaSP.bin'
INPUT_FILE = 'CisnePretoBranco.bin'
OUTPUT_PYTHON = 'resultado_python.bin'
OUTPUT_FPGA = 'resultado_fpga.bin'
OUTPUT_METRICS = 'metricas_performance.csv'

def aes_python_reference(plaintext_bytes):
    cipher = AES.new(SECRET_KEY, AES.MODE_ECB)
    return cipher.encrypt(plaintext_bytes)

def process_file(file_path):
    with open(file_path, 'rb') as f:
        content = f.read()
    
    # Padding para garantir múltiplos de 16 bytes
    content = bytearray(content)
    while len(content) % 16 != 0:
        content.append(0)
        
    blocks = [bytes(content[i:i+16]) for i in range(0, len(content), 16)]
    return blocks

def run_test():
    blocks = process_file(INPUT_FILE)
    num_blocks = len(blocks)

    try:
        # Inicializa a Serial
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=3)
        ser.setDTR(True)
        ser.setRTS(True)
        time.sleep(1)     # Tempo para o hardware estabilizar
        
        # Abrimos os arquivos de saída em modo escrita binária ('wb') para as imagens e ('w') para o CSV
        with (
            open(OUTPUT_PYTHON, 'wb') as f_py, 
            open(OUTPUT_FPGA, 'wb') as f_fpga, 
            open(OUTPUT_METRICS, 'w', newline='') as f_metrics
        ):
            
            # Preparo do CSV de métricas
            writer = csv.writer(f_metrics)
            writer.writerow(['bloco','status','tempo_python_us','tempo_fpga_us','rtt_total_us'])

            print(f"--- Iniciando processamento de {num_blocks} blocos ---")
            start_total = time.perf_counter()
            
            for i, block in enumerate(blocks):
                # 1. Gerar referência via Python
                t_py_start = time.perf_counter()
                expected_cipher = aes_python_reference(block)
                t_py_end = time.perf_counter()

                # 2. Envio para FPGA e medir RTT
                t_rtt_start = time.perf_counter()
                ser.write(block)
                raw_data = ser.read(20)
                t_rtt_end = time.perf_counter()
                
                if (len(raw_data) == 20):
                    fpga_cipher = raw_data[0:16]
                    cycles = int.from_bytes(raw_data[16:20], byteorder='big')

                    # Calculos de tempo us
                    t_py_us = (t_py_end - t_py_start)*1_000_000
                    t_fpga_us = cycles/100
                    t_rtt_us = (t_rtt_end - t_rtt_start)*1_000_000

                    # Salvar dados em formato binário (bytes puros)
                    f_py.write(expected_cipher)
                    f_fpga.write(fpga_cipher)
                    
                    # Metricas
                    status = 'OK' if fpga_cipher == expected_cipher else 'ERRO'
                    writer.writerow([i, status, f'{t_py_us:.3f}', f'{t_fpga_us}', f'{t_rtt_us}'])

                    # Feedback reduzido (apenas a cada 100 blocos para não travar o terminal)
                    if i % 100 == 0 or i == num_blocks - 1:
                        print(f"Progresso: {i+1}/{num_blocks} blocos processados...")

                else:
                    print(f"Erro no Bloco {i}: Dados incompletos.")
            
            end_total = time.perf_counter()
            print(f"\nConcluído em {end_total - start_total:.2f} segundos.")   

        ser.close()
        print(f"Arquivos gerados com sucesso!")
        
    except Exception as e:
        print(f"Erro crítico: {e}")

if __name__ == "__main__":
    run_test()