from PIL import Image
import matplotlib.pyplot as plt
import os

def visualizar_imagem_binaria(bin_path, largura=512, altura=512, colorida=False):
    # 1. Lê os bytes crus do arquivo
    with open(bin_path, 'rb') as f:
        raw_bytes = f.read()
        
    # 2. Calcula o tamanho real esperado da imagem
    bytes_por_pixel = 3 if colorida else 1
    tamanho_esperado = largura * altura * bytes_por_pixel
    
    # 3. Remove o padding (zeros extras) que foi adicionado para o AES (múltiplos de 16)
    if len(raw_bytes) > tamanho_esperado:
        raw_bytes = raw_bytes[:tamanho_esperado]
        
    # 4. Reconstrói a imagem
    modo = 'RGB' if colorida else 'L'
    img_reconstruida = Image.frombytes(modo, (largura, altura), raw_bytes)
    
    # 5. Plota a imagem usando matplotlib
    plt.figure(figsize=(6, 6))
    plt.title(f"Imagem: {os.path.basename(bin_path)}")
    
    if colorida:
        plt.imshow(img_reconstruida)
    else:
        plt.imshow(img_reconstruida, cmap='gray')
        
    plt.axis('off') # Esconde os eixos
    plt.show()

def main():
    # Exemplo de uso:
    # visualizar_imagem_binaria('Imagens/CisnePretoBranco.bin', largura=512, altura=512, colorida=False)
    # visualizar_imagem_binaria('Imagens/resultado_fpga_CisnePretoBranco.bin', largura=512, altura=512, colorida=False)

    # visualizar_imagem_binaria('Imagens/FrutaPadraoConstanteCor.bin', largura=512, altura=512, colorida=True)
    # visualizar_imagem_binaria('Imagens/resultado_fpga_FrutaPadraoConstanteCor.bin', largura=512, altura=512, colorida=True)

    # visualizar_imagem_binaria('Imagens/VistaAereaSP.bin', largura=512, altura=512, colorida=True)
    # visualizar_imagem_binaria('Imagens/resultado_fpga_VistaAereaSP.bin', largura=512, altura=512, colorida=True)
    visualizar_imagem_binaria('Imagens/Resultado AES_ECB/resultado_fpga_vistaAereaSP.bin', largura=512, altura=512, colorida=True)

if __name__ == "__main__":
    main()