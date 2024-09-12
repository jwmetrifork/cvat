# Computer Vision Annotation Tool (CVAT)
This is a fork of [CVAT](https://github.com/cvat-ai/cvat)

## Get Started
Run the `setup_autoannotations.sh` and log in into CVAT at localhost:8080

## Fork contributions
### Setup CVAT for autoannotation
Wrote `setup_autoannotations.sh`, a script to set up CVAT and serverless features for automatic annotation

It set's up Docker containers and installs nuctl for serverless functionality

I've followed [this documentation](https://docs.cvat.ai/docs/administration/advanced/installation_automatic_annotation/).

### Automate the upload of YoloV8 models
Wrote `upload_yolov8_model.sh`, a script to integrate YoloV8 detection models into CVAT.

**Mandatory arguments:**
- **-n:** model_name
- **-p:** path_to_model_weights
- **-v:** ultralytics version used when training the model (Optional, defaults to 8.1.14)

**Usage:**

```console
bash upload_yolov8.sh -n model_name -p path_to_model
```

```console
bash upload_yolov8.sh -n model_name -p path_to_model -v 8.2.0
```

You can check if the serverless functions (the models) are correctly running at localhost:8070 or follow CVAT's automatic annotation documentation to debug

Learned how to integrate Yolo models from [this repo](https://github.com/kurkurzz/custom-yolov8-auto-annotation-cvat-blueprint). Many thanks to @kurkurzz!


## Future additions

### Speed up Cloud Storage integration process
For now follow [this guide](https://docs.cvat.ai/docs/manual/basics/attach-cloud-storage/#google-cloud-storage)

### Add Model Upload UI
Allow to drag and drop a model .pt

### Integrate other model
- YoloV8-seg
- SAM2
- ...

### Figure out how to make it collaborative
Current ideas:
- Host it on a Google Compute Engine with a GPU
- Host it on a Google Compute Engine without a GPU and deploy Nuclio's serverless funcion on Google Kubernetes Engine
- Host it locally and have syncronized annotations
