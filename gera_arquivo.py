import random
import string

FILENAME = 'dados_teste_estresse.txt'
NUM_BLOCKS = 100000
BLOCK_SIZE = 16

def generate_stress_file():
    print(f"Gerando arquivo com {NUM_BLOCKS} blocos...")
    
    # Criamos uma base de caracteres (letras, números e pontuação)
    chars = string.ascii_letters + string.digits + string.punctuation + " "
    
    with open(FILENAME, 'w', encoding='utf-8') as f:
        for _ in range(NUM_BLOCKS):
            # Gera 16 caracteres aleatórios
            block = ''.join(random.choices(chars, k=BLOCK_SIZE))
            f.write(block)
            
    print(f"Sucesso! Arquivo '{FILENAME}' gerado (~{NUM_BLOCKS * BLOCK_SIZE / 1024:.2f} KB).")

if __name__ == "__main__":
    generate_stress_file()