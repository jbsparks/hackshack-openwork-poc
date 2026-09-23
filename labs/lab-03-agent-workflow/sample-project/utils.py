import os
import sys
import json


def read_config(path):
    f = open(path)
    data = json.load(f)
    return data


def merge_dicts(a, b):
    result = {}
    for k in a:
        result[k] = a[k]
    for k in b:
        result[k] = b[k]
    return result


# TODO: add input validation
def parse_csv_line(line):
    parts = line.strip().split(",")
    values = []
    for p in parts:
        try:
            values.append(float(p))
        except:
            values.append(p)
    return values


def flatten(nested_list):
    flat = []
    for item in nested_list:
        if type(item) == list:
            for sub in item:
                flat.append(sub)
        else:
            flat.append(item)
    return flat


def retry(func, times):
    for i in range(times):
        try:
            return func()
        except Exception as e:
            if i == times - 1:
                raise e


def format_bytes(size):
    units = ['B', 'KB', 'MB', 'GB', 'TB']
    i = 0
    while size >= 1024 and i < len(units) - 1:
        size /= 1024
        i += 1
    return f"{size:.1f} {units[i]}"
