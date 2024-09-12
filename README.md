# Computer Vision Annotation Tool (CVAT)
 This is a fork of [CVAT](https://github.com/cvat-ai/cvat)

## Fork contributions
### Setup CVAT for autoannotation
Wrote `setup_autoannotations.sh`, a script to set up CVAT and serverless features for automatic annotation

It set's up Docker containers and installs nuctl for serverless functionality

I've followed (this documentation)[https://docs.cvat.ai/docs/administration/advanced/installation_automatic_annotation/].

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