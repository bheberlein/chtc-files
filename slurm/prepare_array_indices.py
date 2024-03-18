import argparse
import sys

from itertools import tee
from pathlib import Path

import numpy as np


def pairwise(iterable):
    a, b = tee(iterable)
    next(b, None)
    return zip(a, b)


def main(basename):
    
    lakeview = Path('/ships19/hercules/LakeView')
    raw_data_directory = lakeview/f'raw/{basename}'
    
    # Find images
    image_files = sorted(raw_data_directory.glob('*.hyspex'))
    # List image numbers
    indices = sorted(set([int(f.stem.split('_')[2]) for f in image_files]))
    # Find breaks in numbering
    breaks = [0, *(np.diff(indices) > 1).nonzero()[0], len(indices)-1]
    # Get contiguous ranges
    ranges = [(indices[i+1 if i else i], indices[j]) for i, j in pairwise(breaks)]
    # Construct indices for Slurm array jobs
    array_indices = ','.join((f'{a}-{b}' for a, b in ranges))
    
    sys.stdout.write(array_indices)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-n', '--name', type=str, help='Imaging session basename.')
    args = parser.parse_args()
    
    main(args.name)
