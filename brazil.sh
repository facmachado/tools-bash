#!/bin/bash

#
#  brazil.sh - brazil-specific functions library
#
#  Copyright (c) 2023 Flavio Augusto (@facmachado, PP2SH)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#
#  Usage: source random.sh
#         source brazil.sh
#

#
# Verifica se o curl e o jq estão instalados
# (obrigatório para a função banco_nome())
#
if [ ! "$(command -v curl)" ]; then
  echo 'Error: curl not installed' >&2
  exit 1
elif [ ! "$(command -v jq)" ]; then
  echo 'Error: jq not installed' >&2
  exit 1
fi

#
# Fórmulas de cálculo do Digito verificador geral (DAC)
# (General verifier 1-digit calculation formulas)
# (Fonte/Source: Febraban [Brazilian Banks Federation] -
# for use in Brazil - comments below in Portuguese)
#

#
# Módulo 10
# @param {string} numero
# @return {number}
#
function modulo_10() {
  local fila
  local -i a b c d peso
  local -a arr0 arr1
  peso=2

  arr0=("$(rev <<<"${1:-0}" | grep -o .)")
  # shellcheck disable=SC2048
  for a in ${arr0[*]}; do
    fila+=$((a * peso))
    ((peso == 2)) && peso=1 || peso=2
  done
  arr1=("$(grep -o . <<<"$fila")")
  # shellcheck disable=SC2048
  for b in ${arr1[*]}; do c+=$b; done
  d=$((c % 10))
  ((d > 0)) && d=$((10 - d)) || d=0

  printf %d $d
}

#
# Módulo 11
# Obs.: Para o CPF, o segundo parâmetro deverá ter o valor 12, para boletos
#       de cobrança, o valor 10, e para o CNPJ e convênios, o valor 9 (padrão)
# @param {string} numero
# @param {number} fator (9|10|12)
# @return {number}
#
function modulo_11() {
  local -i a b c d digito fator peso
  local -a arr0 arr1
  digito=0  # Valor padrão do DAC
  fator=9   # Fator multiplicatório
  peso=2
  case "$2" in
    12) fator=12 ;;
    10) digito=1 ;;
  esac

  arr0=("$(rev <<<"${1:-0}" | grep -o .)")
  # shellcheck disable=SC2048
  for a in ${arr0[*]}; do
    ((peso > fator)) && peso=2
    arr1+=($((a * peso++)))
  done
  # shellcheck disable=SC2048
  for b in ${arr1[*]}; do c+=$b; done
  d=$((c % 11))
  if ((d > 1 && d < 10)); then
    d=$((11 - d))
  elif ((d < 2)); then
    d=$digito
  else
    d=1
  fi

  printf %d $d
}

#
# Funções auxiliares (para a boleto_info(), por exemplo)
#

#
# Converte o fator de vencimento para Unix timestamp
# @param {string} numero
# @return {number}
#
function venc_utime() {
  local -i b d f s
  f=${1:-0}
  d=86400

  if ((f < 1000 || f > 9999)); then
    echo 'O fator deve estar entre 1000 e 9999' >&2
    return 1
  fi

  b=10141  # O timestamp de 07/10/1997 convertido para dias
  while ((b + 9999 < $(date +%s -u) / d)); do b+=9000; done
  s=$(((f + b) * d))

  printf %d $s
}

#
# Obtém o nome do banco pelo código que consta no boleto
# @param {string} numero
# @return {string}
#
function banco_nome() {
  if ((${#1} < 1)); then
    echo 'Informe o código do banco' >&2
    return 1
  fi

  local c n q u
  c=$(printf %03d "$1")
  u='https://cdn.jsdelivr.net/gh/guibranco/BancosBrasileiros/data/bancos.json'
  q='.[] | select(.COMPE == "'$c'") | .LongName'
  n=$(curl -ks "$u" | jq "$q" | tr -d \")

  printf %s "${n^^}"
}

#
# Funções para CPF e CNPJ - Receita Federal (RFB)
# (Personal Identifiers from Federal Revenue -
# for use in Brazil - comments below in Portuguese)
#

#
# Obtém os 2 últimos dígitos do CPF baseado nos 9 primeiros
# @param {string} numero
# @returns {string}
#
function cpf_dv() {
  if ((${#1} != 9)); then
    echo 'Somente 9 dígitos' >&2
    return 1
  fi

  local d10 d11
  d10=$(modulo_11 "$1" 12)
  d11=$(modulo_11 "$1$d10" 12)

  printf %s "$d10$d11"
}

#
# Gera um número de CPF aleatório válido
# @returns {string}
#
function cpf_gerar() {
  local n
  n=$(random_hash 9)

  printf %s "$n$(cpf_dv "$n")"
}

#
# Valida o número do CPF
# @param {string} numero
# @returns {boolean}
#
function cpf_validar() {
  if ((${#1} != 11)); then
    echo 'Somente 11 dígitos' >&2
    return 1
  fi

  local dv0 dv1 nd
  nd=${1:0:9}
  dv0=${1:9:2}
  dv1=$(cpf_dv "$nd")

  if [[ "$dv1" != "$dv0" ]]; then
    echo 'CPF inválido' >&2
    return 1
  fi
}

#
# Obtém os 2 últimos dígitos do CNPJ baseado nos 12 primeiros
# @param {string} numero
# @returns {string}
#
function cnpj_dv() {
  if ((${#1} != 12)); then
    echo 'Somente 12 dígitos' >&2
    return 1
  fi

  local d13 d14
  d13=$(modulo_11 "$1")
  d14=$(modulo_11 "$1$d13")

  printf %s "$d13$d14"
}

#
# Gera um número de CNPJ aleatório válido
# @returns {string}
#
function cnpj_gerar() {
  local n
  n="$(random_hash 8)0$(random_hash 3)"

  printf %s "$n$(cnpj_dv "$n")"
}

#
# Valida o número do CNPJ
# @param {string} numero
# @returns {boolean}
#
function cnpj_validar() {
  if ((${#1} != 14)); then
    echo 'Somente 14 dígitos' >&2
    return 1
  fi

  local dv0 dv1 nd
  nd=${1:0:12}
  dv0=${1:12:2}
  dv1=$(cnpj_dv "$nd")

  if [[ "$dv1" != "$dv0" ]]; then
    echo 'CNPJ inválido' >&2
    return 1
  fi
}

#
# Funções para operações com boletos bancários brasileiros
# (for use with brazilian bills - comments below in Portuguese)
#

#
# Gera o numérico do código de barras (formato
# Febraban/Intercalado 2 de 5) a partir da linha digitável do boleto. Com
# esse numérico, pode-se gerar a imagem do código de barras ou colá-lo
# em qualquer aplicação de internet banking para pagamento
# @param {string} linha
# @return {string}
#
function boleto_barra() {
  local l
  # shellcheck disable=SC2001
  l=$(sed 's/[^0-9]//g' <<<"$@")
  if ((${#l} != 47)); then
    echo 'Verifique se a linha digitável está correta' >&2
    return 1
  fi

  printf %s "${l:0:4}${l:32:15}${l:4:5}${l:10:10}${l:21:10}"
}

#
# Faz o inverso do boleto_barra(). Requer um leitor de
# código de barras para ler o boleto
# @param {string} barra
# @return {string}
#
function boleto_linha() {
  if ((${#1} != 44)); then
    echo 'O código de barras está ilegível' >&2
    return 1
  fi

  local c1 c2 c3 c4 c5 m1 m2 m3
  c1="${1:0:4}${1:19:1}.${1:20:4}"
  c2="${1:24:5}.${1:29:5}"
  c3="${1:34:5}.${1:39:5}"
  c4="${1:4:1}"   # Digito verificador
  c5="${1:5:14}"  # Vencimento + Valor

  if (($(modulo_11 "${1:0:4}${1:5:39}" 10) != c4)); then
    echo 'O código de barras é inválido' >&2
    return 1
  fi

  m1=$(modulo_10 "${c1//\./}")
  m2=$(modulo_10 "${c2//\./}")
  m3=$(modulo_10 "${c3//\./}")

  printf %s "$c1$m1 $c2$m2 $c3$m3 $c4 $c5"
}

function boleto_info() {
  local c1 c2 c3 c4 c5 l
  # shellcheck disable=SC2001
  l=$(sed 's/[^0-9]//g' <<<"$@")
  if ((${#l} != 47 && ${#l} != 44)); then
    echo 'O código de barras é inválido' >&2
    return 1
  fi
  ((${#l} == 47)) && l=$(boleto_barra "$l")

  c1=${l:0:3}   # Código do banco
  c2=${l:3:1}   # Moeda de emissão: BRL=9
  c3=${l:4:1}   # Digito verificador
  c4=${l:5:4}   # Vencimento
  c5=${l:9:10}  # Valor

  if [[ "$c4" == "0000" ]]; then
    c4='N/D'
  else
    c4=$(date +%d/%m/%Y -ud @"$(venc_utime "$c4")")
  fi

  if [[ "$c5" == "0000000000" ]]; then
    c5='N/D'
  else
    c5=$(printf "%'.2f" "${c5:0:8},${c5:8:2}")
  fi

  cat <<EOF
Banco:               $c1 - $(banco_nome "$c1")
Data do vencimento:  $c4
Valor a pagar:       $c5
EOF
}

#
# Versão do boleto_barra() para contas de Convênio
# (água, energia, telefone, prefeitura, etc.)
# @param {string} linha
# @return {string}
#
function convenio_barra() {
  local l
  # shellcheck disable=SC2001
  l=$(sed 's/[^0-9]//g' <<<"$@")
  if ((${#l} != 48)); then
    echo 'Verifique se a linha digitável está correta' >&2
    return 1
  fi

  printf %s "${l:0:11}${l:12:11}${l:24:11}${l:36:11}"
}

#
# Faz o inverso do convenio_barra()
# @param {string} barra
# @return {string}
#
function convenio_linha() {
  if ((${#1} != 44)); then
    echo 'O código de barras está ilegível' >&2
    return 1
  fi

  local c1 c2 c3 c4 m1 m2 m3 m4
  c1=${1:0:11}
  c2=${1:11:11}
  c3=${1:22:11}
  c4=${1:33:11}

  case ${1:2:1} in
    6|7)
      m1=$(modulo_10 "$c1");
      m2=$(modulo_10 "$c2");
      m3=$(modulo_10 "$c3");
      m4=$(modulo_10 "$c4");
    ;;
    8|9)
      m1=$(modulo_11 "$c1");
      m2=$(modulo_11 "$c2");
      m3=$(modulo_11 "$c3");
      m4=$(modulo_11 "$c4");
    ;;
    *)
      echo 'O código de barras é inválido' >&2
      return 1
    ;;
  esac

  printf %s "$c1-$m1 $c2-$m2 $c3-$m3 $c4-$m4"
}

# TODO: boleto_info e convenio_info
# https://www.banrisul.com.br/bob/data/LeiauteBanrisulFebraban_pdr240_v103_31082021.pdf?cache=0
# https://cmsarquivos.febraban.org.br/Arquivos/documentos/PDF/Layout%20-%20C%C3%B3digo%20de%20Barras%20ATUALIZADO.pdf
# https://download.itau.com.br/bankline/cobranca_cnab240.pdf
