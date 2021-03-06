#!/bin/bash
shopt -s extglob

# Examples
LR_INPUT_DIR="./output/lr"

# Ground truth
HR_INPUT_DIR="./output/hr"

MAX_TILE_COUNT=45500

TRAINING_PERCENTAGE=99
VALIDATION_PERCENTAGE=1

TRAINING_HR_OUTPUT_DIR="output_training/hr"
VALIDATION_HR_OUTPUT_DIR="output_validation/hr"

TRAINING_LR_OUTPUT_DIR="output_training/lr"
VALIDATION_LR_OUTPUT_DIR="output_validation/lr"

# Extra Options

# Clean output allows for a simple output that makes more sense to user executing the script.

CLEAN_OUTPUT=1

for OPTION in "$@"; do
  case ${OPTION} in
    -v|--verbose)
    CLEAN_OUTPUT=0
    shift
    ;;
    -l=*|--lr-input-dir=*)
    LR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -h=*|--hr-input-dir=*)
    HR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -tp=*|--training-percentage=*)
    TRAINING_PERCENTAGE="${OPTION#*=}"
    shift
    ;;
    -vp=*|--validation-percentage=*)
    VALIDATION_PERCENTAGE="${OPTION#*=}"
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
    -mtc=*|--max-tile-count=*)
    MAX_TILE_COUNT="${OPTION#*=}"
    shift
    ;;
    *)
      echo "usage: $@ ..."
      echo "-v, --verbose (default: off)"
      echo "-l, --lr-input-dir \"<lr input dir>\" (default: ${LR_INPUT_DIR})"
      echo "-h, --hr-input-dir \"<hr input dir>\" (default: ${HR_INPUT_DIR})"
      echo "-tp, --training-percentage (default: ${TRAINING_PERCENTAGE})"
      echo "-vp, --validation-percentage (default: ${VALIDATION_PERCENTAGE})"
      echo "--training-hr-output-dir \"<training hr output dir>\" (default: ${TRAINING_HR_OUTPUT_DIR})"
      echo "--validation-hr-output-dir \"<validation hr output dir>\" (default: ${VALIDATION_HR_OUTPUT_DIR})"
      echo "--training-lr-output-dir \"<training lr output dir>\" (default: ${TRAINING_LR_OUTPUT_DIR})"
      echo "--validation-lr-output-dir \"<validation lr output dir>\" (default: ${VALIDATION_LR_OUTPUT_DIR})"
      echo "-mtc, --max-tile-count \"<number>\" (default: ${MAX_TILE_COUNT})"
      exit 1
    ;;
  esac
done

TILE_COUNT=$(find "${HR_INPUT_DIR}" \( -iname "*.dds" -or -iname "*.png" \) | wc -l)

if [ "${TILE_COUNT}" -le "${MAX_TILE_COUNT}" ]; then
  TRAINING_COUNT=$((${TILE_COUNT} * ${TRAINING_PERCENTAGE}/100))
  VALIDATION_COUNT=$((${TILE_COUNT} * ${VALIDATION_PERCENTAGE}/100))
else
  TRAINING_COUNT=$((${MAX_TILE_COUNT} * ${TRAINING_PERCENTAGE}/100))
  VALIDATION_COUNT=$((${MAX_TILE_COUNT} * ${VALIDATION_PERCENTAGE}/100))
fi

mkdir -p "${TRAINING_HR_OUTPUT_DIR}" "${TRAINING_LR_OUTPUT_DIR}" "${VALIDATION_HR_OUTPUT_DIR}" "${VALIDATION_LR_OUTPUT_DIR}"

INDEX=0
INDEX_VAL=0
while read FILENAME; do

  DIRNAME=$(dirname "${FILENAME}")

  BASENAME=$(basename "${FILENAME}")
  BASENAME_NO_EXT="${BASENAME%.*}"

  RELATIVE_DIR=$(realpath --relative-to "${HR_INPUT_DIR}" "${DIRNAME}")

  if [ "${INDEX}" -lt "${TRAINING_COUNT}" ]; then
    if [ "${CLEAN_OUTPUT}" == "0" ]; then
      echo training: ${RELATIVE_DIR}/${BASENAME_NO_EXT}
    else
      #clear
      echo "Processed picture ${INDEX} out of ${TRAINING_COUNT} of the training dataset."
    fi
    cp -a "${HR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}"
    cp -a "${LR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}"
    ((INDEX++))
  else
    if [ "${CLEAN_OUTPUT}" == "0" ]; then
      echo validation: ${RELATIVE_DIR}/${BASENAME_NO_EXT}
    else
      #clear
      echo "Processed picture ${INDEX_VAL} out of ${VALIDATION_COUNT} of the validation dataset."
    fi
    cp -a "${HR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}"
    cp -a "${LR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}"
    ((INDEX_VAL++))
  fi
done < <(find "${HR_INPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \) | shuf -n ${MAX_TILE_COUNT})

echo "finished"
