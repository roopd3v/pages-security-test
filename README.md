# GitHub Pages Build Pipeline — Test Kit

## Setup (faz isto ANTES de qualquer teste)

1. Cria um repo NOVO chamado `pages-security-test` (público)
2. Activa GitHub Pages: Settings → Pages → Source: Deploy from branch → main /root
3. Clona localmente: `git clone git@github.com:TEU_USER/pages-security-test.git`
4. Copia os ficheiros de teste abaixo para o repo
5. `git add -A && git commit -m "test" && git push`
6. Observa o build em Actions tab + o site em TEU_USER.github.io/pages-security-test/

## CRITICAL: NÃO testes em repos de outros. SÓ no teu.

## Vectores de teste (cada um é um commit separado para isolar)

Ver os ficheiros: vector-*.md para instruções específicas.
