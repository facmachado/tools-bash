#!/bin/bash

#
#  brazil.sh - brazil-specific functions library
#
#  Copyright (c) 2022 Flavio Augusto (@facmachado)
#
#  This software may be modified and distributed under the terms
#  of the MIT license. See the LICENSE file for details.
#
#  Usage: source random.sh
#         source brazil.sh
#

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
  for a in ${arr0[*]}; do
    fila+=$((a * peso))
    ((peso == 2)) && peso=1 || peso=2
  done
  arr1=("$(grep -o . <<<"$fila")")
  for b in ${arr1[*]}; do c+=$b; done
  d=$((c % 10))
  ((d > 0)) && d=$((10 - d)) || d=0

  printf %d $d
}

#
# Módulo 11
# Obs.: Para o CPF, o fator multiplicatório deverá ter o valor
#       12, e para o CNPJ e boletos, o valor 9 (padrão)
# @param {string} numero
# @param {number} fator (9|12)
# @return {number}
#
function modulo_11() {
  local -i a b c d fator peso
  local -a arr0 arr1
  peso=2
  [[ "$2" == 12 ]] && fator=12 || fator=9

  arr0=("$(rev <<<"${1:-0}" | grep -o .)")
  for a in ${arr0[*]}; do
    ((peso > fator)) && peso=2
    arr1+=($((a * peso++)))
  done
  for b in ${arr1[*]}; do c+=$b; done
  d=$((c % 11))
  ((d > 1)) && d=$((11 - d)) || d=0

  printf %d $d
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

  if ((dv1 != dv0)); then
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

  if ((dv1 != dv0)); then
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
  c4="${1:4:1}"  # Digito verificador
  c5="${1:5:14}" # Vencimento + Valor

  if (($(modulo_11 "${1:0:4}${1:5:39}") != c4)); then
    echo 'O código de barras é inválido' >&2
    return 1
  fi

  m1=$(modulo_10 "${c1//\./}")
  m2=$(modulo_10 "${c2//\./}")
  m3=$(modulo_10 "${c3//\./}")

  printf %s "$c1$m1 $c2$m2 $c3$m3 $c4 $c5"
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
