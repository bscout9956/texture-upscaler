#!/bin/bash
shopt -s extglob

THREADS="4"

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

# Disable overwriting (may be faster, won't overwrite files that have already been processed)
DISABLE_OVERWRITE="0"

for OPTION in "$@"; do
  case ${OPTION} in
    -t=*|--threads=*)
    THREADS="${OPTION#*=}"
    shift
    ;;
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
    -tl=*|--train-hr-input-dir=*)
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
    -c=*|--max-tile-count=*)
    MAX_TILE_COUNT="${OPTION#*=}"
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
    DISABLE_OVERWRITE="1"
    shift
    ;;
    *)
      echo "usage: $@ ..."
      echo "-t, --threads \"<number>\" (default: ${THREADS})"
      echo "-vl, --val-lr-input-dir \"<val lr input dir>\" (default: ${VAL_LR_INPUT_DIR})"
      echo "-vh, --val-hr-input-dir \"<val hr input dir>\" (default: ${VAL_HR_INPUT_DIR})"
      echo "-tl, --train-lr-input-dir \"<train lr input dir>\" (default: ${TRAIN_LR_INPUT_DIR})"
      echo "-tr, --train-hr-input-dir \"<train hr input dir>\" (default: ${TRAIN_HR_INPUT_DIR})"
      echo "--training-hr-output-dir \"<training hr output dir>\" (default: ${TRAINING_HR_OUTPUT_DIR})"
      echo "--validation-hr-output-dir \"<validation hr output dir>\" (default: ${VALIDATION_HR_OUTPUT_DIR})"
      echo "--training-lr-output-dir \"<training lr output dir>\" (default: ${TRAINING_LR_OUTPUT_DIR})"
      echo "--validation-lr-output-dir \"<validation lr output dir>\" (default: ${VALIDATION_LR_OUTPUT_DIR})"
      echo "-c, --max-tile-count \"<number>\" (default: ${MAX_TILE_COUNT})"
      echo "-ls, --lr-tile-size \"<dimensions>\" (default: ${LR_SIZE})"
      echo "-hs, --hr-tile-size \"<dimensions>\" (default: ${HR_SIZE})"
      echo "-dl, --disable-logging"
      echo "-do, --disable-overwrite"
      exit 1
    ;;
  esac
done

wait_for_jobs() {
  local JOBLIST=($(jobs -p))
  if [ "${#JOBLIST[@]}" -gt "${THREADS}" ]; then
    for JOB in ${JOBLIST}; do
      echo Waiting for job ${JOB}...
      wait ${JOB}
    done
  fi
}

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
    if [ "${DISABLE_LOGGING}" == "0" ]; then
      echo train LR and HR: "${BASENAME_NO_EXT}"
    fi
    
    # Check whether the LR and HR already exist. Skip if overwite is disabled
    if [[ ( ! -f "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}" || ! -f "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}" ) && "${DISABLE_OVERWRITE}" == "0" ]]; then
	  wait_for_jobs
      convert "${TRAIN_LR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${LR_SIZE}"+0+0 +repage "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}"
      wait_for_jobs
      convert "${TRAIN_HR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${HR_SIZE}"+0+0 +repage "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}"
    elif [ "${DISABLE_OVERWRITE}" == "1" ]; then
      if [[ ! -f "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}" || ! -f "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}" ]]; then
	    wait_for_jobs
        convert "${TRAIN_LR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${LR_SIZE}"+0+0 +repage "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}"
		wait_for_jobs
        convert "${TRAIN_HR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${HR_SIZE}"+0+0 +repage "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}"
      elif [ "${DISABLE_LOGGING}" == "0" ]; then        
        echo "${BASENAME} may already exist, skipping"      
      fi
    fi
    continue 
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
    if [ "${DISABLE_LOGGING}" == "0" ]; then
      echo validation LR and HR: "${BASENAME_NO_EXT}"
    fi

    # Check whether the LR and HR already exist. Skip if overwrite is disabled
    # TODO: Prettify this, it's borderline unreadable
    if [[ ( ! -f "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}" || ! -f "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}" ) && "${DISABLE_OVERWRITE}" == "0" ]]; then
      wait_for_jobs
      convert "${VAL_LR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${LR_SIZE}"+0+0 +repage "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}"
      wait_for_jobs
      convert "${VAL_HR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${HR_SIZE}"+0+0 +repage "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}"
    elif [ "$DISABLE_OVERWRITE" == "1" ]; then
      if [[ ! -f "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}" || ! -f "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}" ]]; then
        wait_for_jobs
        convert "${VAL_LR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${LR_SIZE}"+0+0 +repage "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}"
        wait_for_jobs
        convert "${VAL_HR_INPUT_DIR}/${BASENAME}" -gravity Center -crop "${HR_SIZE}"+0+0 +repage "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}"
      elif [ "${DISABLE_LOGGING}" == "0" ]; then        
        echo "${BASENAME} may already exist, skipping"      
      fi
    fi
    continue 
  fi

  ((INDEX_VAL++))
done < <(find "${VAL_HR_INPUT_DIR}" \( -iname "*.jpg" -or -iname "*.dds" -or -iname "*.png" \))

wait_for_jobs
wait

echo "Finished processing"
