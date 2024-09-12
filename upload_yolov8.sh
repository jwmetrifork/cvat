#!/bin/bash

###############################################################################
# Usage Function to Display Help
###############################################################################
usage() {
    echo "Usage: $0 -n <model_name> -p <model_path> [-v <ultralytics_version>]"
    echo ""
    echo "Arguments:"
    echo "  -n   Model name (for the folder and YAML) (required)"
    echo "  -p   Path to the model (.pt file) (required)"
    echo "  -v   Ultralytics version to be installed (optional, default: 8.1.14)"
    echo ""
    exit 1
}

###############################################################################
# Default value for optional arguments
###############################################################################
ULTRALYTICS_VERSION="8.1.14"  # Set default value for Ultralytics version

###############################################################################
# Parse Command-line Arguments
###############################################################################
while getopts "n:p:v:h" opt; do
    case $opt in
        n) MODEL_NAME="yolov8-$OPTARG" ;;
        p) MODEL_PATH="$OPTARG" ;;
        v) ULTRALYTICS_VERSION="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$MODEL_NAME" || -z "$MODEL_PATH" ]]; then
    echo "Error: -n (model name) and -p (model path) are required."
    usage
fi

MODEL_FOLDER="serverless/custom_models/$MODEL_NAME"

###############################################################################
# Step 1: Check if the model folder exists
###############################################################################
if [ -d "$MODEL_FOLDER" ]; then
    echo "Custom model directory already exists: $MODEL_FOLDER"
else
    echo "Creating custom model folder: $MODEL_FOLDER"
    mkdir -p "$MODEL_FOLDER"
fi

###############################################################################
# Step 2: Copy the model .pt file to the custom model folder
###############################################################################
echo "Copying model .pt file to $MODEL_FOLDER..."
cp "$MODEL_PATH" "$MODEL_FOLDER/"

###############################################################################
# Step 3: Create main.py
###############################################################################
echo "Creating main.py..."
cat <<EOL > ${MODEL_FOLDER}/main.py
import io
import base64
import json
import cv2
import numpy as np
from ultralytics import YOLO

def init_context(context):
    context.logger.info('Init context...  0%')
    model = YOLO('$(basename "$MODEL_PATH")')
    context.user_data.model_handler = model
    context.logger.info('Init context...100%')

def handler(context, event):
    context.logger.info('Run custom yolov8 model')
    data = event.body
    image_buffer = io.BytesIO(base64.b64decode(data['image']))
    image = cv2.imdecode(np.frombuffer(image_buffer.getvalue(), np.uint8), cv2.IMREAD_COLOR)

    results = context.user_data.model_handler(image)
    result = results[0]

    boxes = result.boxes.data[:,:4]
    confs = result.boxes.conf
    clss = result.boxes.cls
    class_name = result.names

    detections = []
    threshold = 0.1
    for box, conf, cls in zip(boxes, confs, clss):
        label = class_name[int(cls)]
        if conf >= threshold:
            detections.append({
                'confidence': str(float(conf)),
                'label': label,
                'points': box.tolist(),
                'type': 'rectangle',
            })

    return context.Response(body=json.dumps(detections), headers={},
        content_type='application/json', status_code=200)
EOL

###############################################################################
# Step 4: Extract class names from the model using Python
###############################################################################
echo "Extracting class names from the model..."
CLASS_SPEC=$(python3 <<EOF
import torch
import json

def extract_class_names(model_path):
    model = torch.load(model_path, map_location='cpu')
    class_names = model['model'].names
    class_spec = [{"id": idx, "name": name} for idx, name in class_names.items()]
    return class_spec

model_path = "${MODEL_PATH}"
class_spec = extract_class_names(model_path)
print(json.dumps(class_spec))
EOF
)

###############################################################################
# Step 5: Create function-gpu.yaml and insert class names into spec with correct formatting
###############################################################################
echo "Updating function-gpu.yaml with class names..."
CLASS_SPEC_SINGLE_LINE=$(echo "$CLASS_SPEC" | jq -c '.')

cat <<EOL > ${MODEL_FOLDER}/function-gpu.yaml
metadata:
  name: ${MODEL_NAME}
  namespace: cvat
  annotations:
    name: ${MODEL_NAME}
    type: detector
    framework: pytorch
    spec: |
      ${CLASS_SPEC_SINGLE_LINE}
spec:
  description: ${MODEL_NAME}
  runtime: 'python:3.9'
  handler: main:handler
  eventTimeout: 30s

  build:
    image: ${MODEL_NAME}
    baseImage: ubuntu:22.04

    directives:
      preCopy:
        - kind: ENV
          value: DEBIAN_FRONTEND=noninteractive
        - kind: RUN
          value: apt-get update && apt-get -y install curl git python3 python3-pip
        - kind: RUN
          value: apt-get -y install libgl1-mesa-glx libglib2.0-dev
        - kind: WORKDIR
          value: /opt/nuclio
        - kind: RUN
          value: pip3 install ultralytics==${ULTRALYTICS_VERSION} opencv-python==4.7.0.72 numpy==1.24.3
        - kind: RUN
          value: ln -s /usr/bin/pip3 /usr/local/bin/pip
        - kind: RUN
          value: ln -s /usr/bin/python3 /usr/local/bin/python

  triggers:
    myHttpTrigger:
      maxWorkers: 1
      kind: 'http'
      workerAvailabilityTimeoutMilliseconds: 10000
      attributes:
        maxRequestBodySize: 33554432 # 32MB

  platform:
    attributes:
      restartPolicy:
        name: always
        maximumRetryCount: 3
      mountMode: volume
EOL

echo "function-gpu.yaml has been updated with the class names and model information."

###############################################################################
# Step 6: Run the deployment script for the custom model
###############################################################################
echo "Running the deployment script..."
bash serverless/deploy_gpu.sh $MODEL_FOLDER
