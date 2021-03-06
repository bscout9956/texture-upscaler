#!/bin/bash
shopt -s extglob

# Examples
VAL_LR_INPUT_DIR="./output_validation/LR"
TRAIN_LR_INPUT_DIR="./output_training/LR"

# Ground truth
VAL_HR_INPUT_DIR="./output_validation/HR"
TRAIN_HR_INPUT_DIR="./output_training/HR"

TRAINING_HR_OUTPUT_DIR="datasets/train/HR"
VALIDATION_HR_OUTPUT_DIR="datasets/val/HR"

TRAINING_LR_OUTPUT_DIR="datasets/train/LR"
VALIDATION_LR_OUTPUT_DIR="datasets/val/LR"

# Desired sizes for the LR and HR tiles
LR_SIZE="32x32"
HR_SIZE="128x128"

# Disable unnecessary logging if desired
DISABLE_LOGGING="0"
CLEAN_OUTPUT="1"

# Enable overwriting (Disabling might be faster, as it won't overwrite files that have already been processed)
ENABLE_OVERWRITE="1"

for OPTION in "$@"; do
  case ${OPTION} in
    -vl=*|--val-lr-input-dir=*)
    VAL_LR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -vh=*|--val-hr-input-dir=*)
    VAL_HR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -tl=*|--train-lr-input-dir=*)
    TRAIN_LR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -th=*|--train-hr-input-dir=*)
    TRAIN_HR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    --training-hr-output-dir=*)
    TRAINING_HR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    --validation-hr-output-dir=*)
    VALIDATION_HR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    --training-lr-output-dir=*)
    TRAINING_LR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    --validation-lr-output-dir=*)
    VALIDATION_LR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -ls=*|--lr-tile-size=*)
    LR_SIZE="${OPTION#*=}"
    shift
    ;;
    -hs=*|--hr-tile-size=*)
    HR_SIZE="${OPTION#*=}"
    shift
    ;;
    -dl|--disable-logging)
    DISABLE_LOGGING="1"
    shift
    ;;
    -do|--disable-overwrite)
    ENABLE_OVERWRITE="0"
    shift
    ;;
    *)
      echo "usage: $@ ..."
      echo "-vl, --val-lr-input-dir \"<val lr input dir>\" (default: ${VAL_LR_INPUT_DIR})"
      echo "-vh, --val-hr-input-dir \"<val hr input dir>\" (default: ${VAL_HR_INPUT_DIR})"
      echo "-tl, --train-lr-input-dir \"<train lr input dir>\" (default: ${TRAIN_LR_INPUT_DIR})"
      echo "-tr, --train-hr-input-dir \"<train hr input dir>\" (default: ${TRAIN_HR_INPUT_DIR})"
      echo "--training-hr-output-dir \"<training hr output dir>\" (default: ${TRAINING_HR_OUTPUT_DIR})"
      echo "--validation-hr-output-dir \"<validation hr output dir>\" (default: ${VALIDATION_HR_OUTPUT_DIR})"
      echo "--training-lr-output-dir \"<training lr output dir>\" (default: ${TRAINING_LR_OUTPUT_DIR})"
      echo "--validation-lr-output-dir \"<validation lr output dir>\" (default: ${VALIDATION_LR_OUTPUT_DIR})"
      echo "-ls, --lr-tile-size \"<dimensions>\" (default: ${LR_SIZE})"
      echo "-hs, --hr-tile-size \"<dimensions>\" (default: ${HR_SIZE})"
      echo "-dl, --disable-logging (default: ${DISABLE_LOGGING})"
      echo "-do, --disable-overwrite"
      exit 1
    ;;
  esac
done

LR_VAL_TILE_COUNT=$(find "${VAL_LR_INPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \) | wc -l)
LR_TRAIN_TILE_COUNT=$(find "${TRAIN_LR_INPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \) | wc -l)
HR_VAL_TILE_COUNT=$(find "${VAL_HR_INPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \) | wc -l)
HR_TRAIN_TILE_COUNT=$(find "${TRAIN_HR_INPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \) | wc -l)

mkdir -p "${TRAINING_HR_OUTPUT_DIR}" "${TRAINING_LR_OUTPUT_DIR}" "${VALIDATION_HR_OUTPUT_DIR}" "${VALIDATION_LR_OUTPUT_DIR}"

echo "Processsing the training dataset..."

INDEX_TRAIN=0
while read FILENAME; do
  DIRNAME=$(dirname "${FILENAME}")
  BASENAME=$(basename "${FILENAME}")
  BASENAME_NO_EXT="${BASENAME%.*}"

  if [ "${INDEX_TRAIN}" -lt "${LR_TRAIN_TILE_COUNT}" ]; then
    if [[ "${DISABLE_LOGGING}" == "0" || "${CLEAN_OUTPUT}" == "0" ]]; then
      echo train LR and HR: "${BASENAME_NO_EXT}"
    fi
    
    if [ "${CLEAN_OUTPUT}" == "0" ]; then
      echo train LR and HR: "${BASENAME_NO_EXT}"
    else
      clear
      echo "Processed picture ${INDEX_TRAIN} out of ${LR_TRAIN_TILE_COUNT} of the training dataset."
    fi

    # Check whether the LR and HR already exists. Skip existing files if overwrite is disabled.
    if [ "${ENABLE_OVERWRITE}" == "1" ]; then
      convert "${TRAIN_LR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${LR_SIZE}"+0+0 +repage "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}"      
      convert "${TRAIN_HR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${HR_SIZE}"+0+0 +repage "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}"
    else
      if [[ -f "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}" && -f "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}" ]]; then
        if [ "${DISABLE_LOGGING}" == "0" ]; then
          echo "${BASENAME} already exists, skipping."
        fi
        ((INDEX_TRAIN++))
        continue
      else        
        convert "${TRAIN_LR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${LR_SIZE}"+0+0 +repage "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}"        
        convert "${TRAIN_HR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${HR_SIZE}"+0+0 +repage "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}"
      fi
    fi
  fi

  ((INDEX_TRAIN++))
done < <(find "${TRAIN_HR_INPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \))

echo "Processsing the validation dataset..."

INDEX_VAL=0
while read FILENAME; do

  DIRNAME=$(dirname "${FILENAME}")
  BASENAME=$(basename "${FILENAME}")
  BASENAME_NO_EXT="${BASENAME%.*}"

  if [ "${INDEX_VAL}" -lt "${LR_VAL_TILE_COUNT}" ]; then
    if [[ "${DISABLE_LOGGING}" == "0" || "${CLEAN_OUTPUT}" == "0" ]]; then
      echo val LR and HR: "${BASENAME_NO_EXT}"
    fi
    
    if [ "${CLEAN_OUTPUT}" == "0" ]; then
      echo val LR and HR: "${BASENAME_NO_EXT}"
    else
      clear
      echo "Processed picture ${INDEX_VAL} out of ${LR_VAL_TILE_COUNT} of the validation dataset."
    fi

    # Check whether the LR and HR already exists. Skip existing files if overwrite is disabled.

    if [ "${ENABLE_OVERWRITE}" == "1" ]; then      
      convert "${VAL_LR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${LR_SIZE}"+0+0 +repage "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}"      
      convert "${VAL_HR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${HR_SIZE}"+0+0 +repage "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}"
    else
      if [[ -f "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}" && -f "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}" ]]; then
        if [ "${DISABLE_LOGGING}" == "0" ]; then
          echo "${BASENAME} already exists, skipping."
        fi
        ((INDEX_VAL++))
        continue
      else        
        convert "${VAL_LR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${LR_SIZE}"+0+0 +repage "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}"        
        convert "${VAL_HR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${HR_SIZE}"+0+0 +repage "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}"
      fi
    fi
  fi
  ((INDEX_VAL++))
done < <(find "${VAL_HR_INPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \))

echo "Finished processing"
