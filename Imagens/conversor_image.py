from PIL import Image

def preparar_imagem_para_fpga(image_path, output_bin_path, largura=512, altura=512, colorida=False):
    # 1. Abre a imagem
    img = Image.open(image_path)
    
    # 2. Redimensiona para garantir que todas tenham o mesmo tamanho exato
    img = img.resize((largura, altura))
    
    # 3. Converte o modo de cor
    if colorida:
        img = img.convert('RGB')  # 3 bytes por pixel
    else:
        img = img.convert('L')    # 1 byte por pixel (Escala de Cinza)
        
    # 4. Transforma em uma sequência de bytes puros
    pixel_bytes = bytearray(img.tobytes())
    
    # 5. Garante o alinhamento com o bloco do AES (múltiplo de 16)
    while len(pixel_bytes) % 16 != 0:
        pixel_bytes.append(0) # Padding com zeros se necessário
        
    # 6. Salva o arquivo binário que será lido pelo seu script UART
    with open(output_bin_path, 'wb') as f:
        f.write(pixel_bytes)
        
    print(f"Imagem {image_path} convertida para {output_bin_path} ({len(pixel_bytes)} bytes).")

# Exemplo de uso:
# preparar_imagem_para_fpga('sua_imagem.jpg', 'dados_teste_estresse.bin', largura=512, altura=512, colorida=False)