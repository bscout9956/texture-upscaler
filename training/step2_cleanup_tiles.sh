#!/bin/bash
shopt -s extglob

# Min colors treshold
MIN_COLORS=8

# Min and max must be equal
HR_MIN_TILE_WIDTH=128
HR_MIN_TILE_HEIGHT=128

HR_MAX_TILE_WIDTH=128
HR_MAX_TILE_HEIGHT=128

# Examples
LR_OUTPUT_DIR="./output/LR"

# Ground truth
HR_OUTPUT_DIR="./output/HR"

for OPTION in "$@"; do
  case ${OPTION} in
    -mc=*|--min-colors=*)
    MIN_COLORS="${OPTION#*=}"
    shift
    ;;
    -l=*|--lr-output-dir=*)
    LR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -h=*|--hr-output-dir=*)
    HR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -tw=*|--tile-width=*)
    HR_MIN_TILE_WIDTH="${OPTION#*=}"
    HR_MAX_TILE_WIDTH="${OPTION#*=}"
    shift
    ;;
    -th=*|--tile-height=*)
    HR_MIN_TILE_HEIGHT="${OPTION#*=}"
    HR_MAX_TILE_HEIGHT="${OPTION#*=}"
    shift
    ;;
    *)
      echo "usage: $@ ..."
      echo "-t, --threads \"<number>\" (default: ${THREADS})"
      echo "-mc, --min-colors \"<number>\" (default: ${MIN_COLORS})"
      echo "-l, --lr-output-dir \"<lr output dir>\" (default: ${LR_OUTPUT_DIR})"
      echo "-h, --hr-output-dir \"<hr output dir>\" (default: ${HR_OUTPUT_DIR})"
      echo "-tw, --tile-width \"<pixels>\" (default: ${HR_MIN_TILE_WIDTH})"
      echo "-th, --tile-height \"<pixels>\" (default: ${HR_MIN_TILE_HEIGHT})"
      exit 1
    ;;
  esac
done

cleanup_task() {

  FILENAME="$@"

  DIRNAME=$(dirname "${FILENAME}")

  BASENAME=$(basename "${FILENAME}")
  BASENAME_NO_EXT="${BASENAME%.*}"

  IMAGE_INFO=$(identify -format '%[width] %[height] %[channels] %[k]' "${FILENAME}")
  IMAGE_WIDTH=$(echo ${IMAGE_INFO} | cut -d' ' -f 1)
  IMAGE_HEIGHT=$(echo ${IMAGE_INFO} | cut -d' ' -f 2)
  IMAGE_COLORS=$(echo ${IMAGE_INFO} | cut -d' ' -f 4)
  IMAGE_CHANNELS=$(echo ${IMAGE_INFO} | cut -d' ' -f 3)

  RELATIVE_DIR=$(realpath --relative-to "${HR_OUTPUT_DIR}" "${DIRNAME}")

  echo ${RELATIVE_DIR}/${BASENAME_NO_EXT} \(${IMAGE_WIDTH} ${IMAGE_HEIGHT} ${IMAGE_CHANNELS} ${IMAGE_COLORS}\)

  if [ "${IMAGE_COLORS}" -le "${MIN_COLORS}" ]; then
    echo ${BASENAME_NO_EXT}, too little colors \(${IMAGE_COLORS}\), delete
    rm -f ${HR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    rm -f ${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    return
  fi

  if [ "${IMAGE_CHANNELS}" != "rgb" ] && [ "${IMAGE_CHANNELS}" != "srgb" ]; then
    echo ${BASENAME_NO_EXT}, not rgb \(${IMAGE_CHANNELS}\), delete
    rm -f ${HR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    rm -f ${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    return
  fi

  if [ "${IMAGE_WIDTH}" -lt "${HR_MIN_TILE_WIDTH}" ] || [ "${IMAGE_HEIGHT}" -lt "${HR_MIN_TILE_HEIGHT}" ]; then
    echo ${BASENAME_NO_EXT}, too small \(${IMAGE_WIDTH}x${IMAGE_HEIGHT}\), delete
    rm -f ${HR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    rm -f ${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    return
  fi

  if [ "${IMAGE_WIDTH}" -gt "${HR_MAX_TILE_WIDTH}" ] || [ "${IMAGE_HEIGHT}" -gt "${HR_MAX_TILE_HEIGHT}" ]; then
    echo ${BASENAME_NO_EXT}, too big \(${IMAGE_WIDTH}x${IMAGE_HEIGHT}\), delete
    rm -f ${HR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    rm -f ${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    return
  fi

}

while read FILENAME; do
 cleanup_task ${FILENAME} &
done < <(find "${HR_OUTPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \))

echo "finished"
