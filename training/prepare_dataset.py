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
# TODO: Add scaling settings for LR

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
    if get_random_number(0, 1) == 0:
        return "NEAREST"
    else:
        return "BICUBIC"

# TODO: Condense process_hr and process_lr into one thing


def process_hr(image, filename):
    opt_dir = output_folder + slash + "hr"

    # I am not sure how to make this properly. Submit a Pull Request if you find an alternative.

    h_divs = floor(image.width / hr_size)
    v_divs = floor(image.height / hr_size)

    if path.isdir(opt_dir):
        for i in range(0, v_divs):
            for j in range(0, h_divs):
                """ 
                Useful for 'debugging'
                print(hr_size * j, hr_size * i, hr_size * (j + 1), hr_size * (i + 1))
                """
                try:
                    image_copy = image.crop((hr_size * j, hr_size * i, hr_size * (j + 1), hr_size * (i + 1)))
                except OSError:
                    print(
                        "It is possible that a corrupt or truncated image has been found. Skipping {}".format(filename))
                image_copy.save(opt_dir + slash + filename + "tile_0{}{}".format(i, j) + ".png", "PNG",
                                icc_profile=image.info.get('icc_profile'))
    else:
        makedirs(opt_dir)
        return process_hr(image, filename)


def process_lr(image, filename):
    opt_dir = output_folder + slash + "lr"

    # May crop the right side of the image... For now, that's it.

    h_divs = floor(image.width / lr_size)
    v_divs = floor(image.height / lr_size)

    if not path.isdir(opt_dir):
        makedirs(opt_dir)
    else:
        for i in range(0, v_divs):
            for j in range(0, h_divs):
                # print(lr_size * j, lr_size * i, lr_size * (j + 1), lr_size * (i + 1))
                try:
                    image_copy = image.crop((lr_size * j, lr_size * i, lr_size * (j + 1), lr_size * (i + 1)))
                except OSError:
                    print(
                        "It is possible that a corrupt or truncated image has been found. Skipping {}".format(filename))
                if random_lr_scaling:
                    image_copy = image_copy.resize((lr_size, lr_size), get_filter())
                else:
                    image_copy = image_copy.resize((lr_size, lr_size), 0)
                image_copy.save(opt_dir + slash + filename + "tile_0{}{}".format(i, j) + ".png", "PNG")


# def process_images(image_path, pic_name):
# global rgb_index
# picture = Im.open(image_path, "r")
# if picture.mode != "RGB":
# picture = picture.convert(mode="RGB")
# rgb_index += 1
# process_lr(picture, pic_name)
# process_hr(picture, pic_name)


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
            process_lr(picture, filename)
            process_hr(picture, filename)

            # process_images(pic_path, filename)
            index += 1
    print("{} pictures were converted to RGB.".format(rgb_index))


if __name__ == "__main__":
    main()
