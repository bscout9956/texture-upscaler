from PIL import Image as Im
from PIL import ImageFile
from os import walk, path, makedirs, listdir, name
import random
import time
from math import floor

# Helper Variables and Flags

slash = "\\" if name == 'nt' else "/"
ImageFile.LOAD_TRUNCATED_IMAGES = True

# Folders

input_folder = "." + slash + "input"
output_folder = "." + slash + "output"

# Tile Settings

scale = 4
hr_size = 128
lr_size = hr_size / scale
random_lr_scaling = False
lr_scaling = "NEAREST"

# Indexes

rgb_index = 0


def get_random_number(start, end):
    # Use time as a seed, makes it more randomized
    random.seed(time.time_ns())
    return random.randint(start, end)


def check_file_count(ifolder):
    file_count = 0
    for root, dirs, files in walk(ifolder):
        file_count += len(files)
    return file_count


def get_filter():
    if random_lr_scaling:
        if get_random_number(0, 1) == 0:
            return "NEAREST"
        else:
            return "BICUBIC"
    else:
        return lr_scaling


def process_image(image, filename):
    output_dir = output_folder + slash
    lr_output_dir = output_dir + "lr"
    hr_output_dir = output_dir + "hr"

    h_lr_divs = floor(image.width / lr_size)
    v_lr_divs = floor(image.height / lr_size)
    h_hr_divs = floor(image.width / hr_size)
    v_hr_divs = floor(image.height / hr_size)

    if not path.isdir(output_dir):
        makedirs(lr_output_dir)
        makedirs(hr_output_dir)
    else:
        # LR
        for i in range(v_lr_divs):
            for j in range(h_lr_divs):
                image_copy = image.crop((lr_size * j, lr_size * i, lr_size * (j + 1), lr_size * (i + 1)))
                image_copy = image_copy.resize((lr_size, lr_size), get_filter())
                image_copy.save(output_dir + slash + filename + "tile_0{}{}".format(i, j) + ".png", "PNG",
                                icc_profile=image.info.get('icc_profile'))
        # HR
        for i in range(v_hr_divs):
            for j in range(h_hr_divs):
                image_copy = image.crop((hr_size * j, hr_size * i, hr_size * (j + 1), hr_size * (i + 1)))
                image_copy.save(output_dir + slash + filename + "tile_0{}{}".format(i, j) + ".png", "PNG",
                                icc_profile=image.info.get('icc_profile'))


def main():
    global rgb_index
    file_count = check_file_count(input_folder)
    index = 1
    for filename in listdir(input_folder):
        if filename.endswith("jpg") or filename.endswith("dds") or filename.endswith("png"):
            print("Processing Picture {} of {}".format(index, file_count))
            pic_path = input_folder + slash + filename
            picture = Im.open(pic_path, "r")
            if picture.mode != "RGB":
                picture = picture.convert(mode="RGB")
                rgb_index += 1
            process_image(picture, filename)

            # process_images(pic_path, filename)
            index += 1
    print("{} pictures were converted to RGB.".format(rgb_index))


if __name__ == "__main__":
    main()
