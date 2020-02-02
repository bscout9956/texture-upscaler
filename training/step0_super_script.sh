#!/bin/bash
shopt -s extglob

# Options

THREADS="4"
INPUT_DIR="./input"

# Scaling Options
BASE_SCALE=128 # Square tiles
LR_SCALE=25%
HR_SCALE=100%
ENABLE_RANDOM_FILTERSCALE=1

# Extra
MIN_COLORS=8
AVOID_STEP2=1
AVOID_STEP4=0
DISABLE_LOGGING=0

# Tile Options
MAX_TILE_COUNT=1000
TRAINING_PERCENTAGE=80
VALIDATION_PERCENTAGE=20


for OPTION in "$@"; do
  case ${OPTION} in
    -t=*|--threads=*)
    THREADS="${OPTION#*=}"
    shift
    ;;
	-i=*|--input-dir=*)
    INPUT_DIR="${OPTION#*=}"
    shift
    ;;
	-mc=*|--min-colors=*)
    MIN_COLORS="${OPTION#*=}"
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
	-mtc=*|--max-tile-count=*)
    MAX_TILE_COUNT="${OPTION#*=}"
    shift
    ;;
	-as2|--avoid-step2)
	AVOID_STEP2=1
	shift
	;;
	-as4|--avoid-step4)
	AVOID_STEP4=1
	shift
	;;
	-dl|--disable-logging)
    DISABLE_LOGGING="1"
    shift
    ;;
    *)
      echo "usage: $@ ..."
      echo "-t, --threads \"<number>\" (default: ${THREADS})"
	  echo "-i, --input-dir \"<input dir>\" (default: ${INPUT_DIR})"
	  echo "-mc, --min-colors \"<number>\" (default: ${MIN_COLORS})"
	  echo "-tp, --training-percentage (default: ${TRAINING_PERCENTAGE})"
      echo "-vp, --validation-percentage (default: ${VALIDATION_PERCENTAGE})"
	  echo "-mtc, --max-tile-count \"<number>\" (default: ${MAX_TILE_COUNT})"
	  echo "-as2, --avoid-step2 (default: ${AVOID_STEP2})"
	  echo "-as4, --avoid-step4 (default: ${AVOID_STEP4})"
	  echo "-dl, --disable-logging (default: ${DISABLE_LOGGING})"
      exit 1
    ;;
  esac
done

echo "Step 1 - Create Tiles"

./step1_create_tiles.sh --threads "${THREADS}" --lr-scale "${LR_SCALE}" --hr-scale "${HR_SCALE}" --tile-width "${BASE_SCALE}" --tile-height "${BASE_SCALE}" --random-filtering

if [ "${AVOID_STEP2}" == "1" ]; then
  echo "Step 2 will be skipped"
else
  echo "Step 2 - Cleanup Tiles"
  ./step2_cleanup_tiles.sh --threads "${THREADS}" --min-colors "${MIN_COLORS}" --lr-output-dir --tile-width "${BASE_SCALE}" --tile-height "${BASE_SCALE}"
fi

echo "Step 3 - Select Tiles"

./step3_select_tiles.sh --threads "${THREADS}" --training-percentage "${TRAINING_PERCENTAGE}" --validation-percentage "${VALIDATION_PERCENTAGE}" --max-tile-count "${MAX_TILE_COUNT}"

if [ "${AVOID_STEP4}" == "1" ]; then
  echo "Step 4 will be skipped"
else
  echo "Step 4 - Crop Center"
  if [ "${DISABLE_LOGGING}" == "1" ]; then
    ./step4_crop_center.sh --threads "${THREADS}" --disable-logging
  else
    ./step4_crop_center.sh --threads "${THREADS}"
  fi
  
fi

echo "Super Script Finished"
