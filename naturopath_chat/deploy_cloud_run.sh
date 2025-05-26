#!/bin/bash

# Script to build and deploy the Flask app to Google Cloud Run

# --- Configuration - User can override these with environment variables ---
GCP_PROJECT_ID=${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}
SERVICE_NAME=${SERVICE_NAME:-"naturopath-chat"}
REGION=${REGION:-"us-central1"} # Default region, user can change
ARTIFACT_REGISTRY_REPO=${ARTIFACT_REGISTRY_REPO:-"naturopath-chat-repo"} # Default repo name
IMAGE_NAME_BASE="naturopath-app" # Base name for the image

# --- Ensure gcloud and docker are installed ---
if ! command -v gcloud &> /dev/null; then
    echo "gcloud command-line tool not found. Please install and configure Google Cloud SDK."
    exit 1
fi
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker."
    exit 1
fi

# --- Get GCP Project ID ---
if [ -z "$GCP_PROJECT_ID" ]; then
    read -r -p "Enter your Google Cloud Project ID: " GCP_PROJECT_ID
    if [ -z "$GCP_PROJECT_ID" ]; then
        echo "Error: GCP Project ID is required."
        exit 1
    fi
    gcloud config set project "$GCP_PROJECT_ID"
    echo "Set GCP Project ID to $GCP_PROJECT_ID"
else
    echo "Using GCP Project ID: $GCP_PROJECT_ID (from gcloud config or environment variable)"
fi

# --- Get Region for deployment ---
read -r -p "Enter deployment region (default: $REGION): " INPUT_REGION
REGION=${INPUT_REGION:-$REGION}
echo "Using region: $REGION"

# --- Get Service Name for Cloud Run ---
read -r -p "Enter Cloud Run Service Name (default: $SERVICE_NAME): " INPUT_SERVICE_NAME
SERVICE_NAME=${INPUT_SERVICE_NAME:-$SERVICE_NAME}
echo "Using Cloud Run service name: $SERVICE_NAME"

# --- Get Artifact Registry Repository Name ---
read -r -p "Enter Artifact Registry Repository name (default: $ARTIFACT_REGISTRY_REPO): " INPUT_ARTIFACT_REGISTRY_REPO
ARTIFACT_REGISTRY_REPO=${INPUT_ARTIFACT_REGISTRY_REPO:-$ARTIFACT_REGISTRY_REPO}
echo "Using Artifact Registry repository: $ARTIFACT_REGISTRY_REPO"

# Define the full image name for Artifact Registry
IMAGE_TAG_LATEST="${REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REGISTRY_REPO}/${IMAGE_NAME_BASE}:latest"
IMAGE_TAG_VERSIONED="${REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${ARTIFACT_REGISTRY_REPO}/${IMAGE_NAME_BASE}:$(date +%Y%m%d-%H%M%S)"

# --- Check if Artifact Registry repository exists, create if not ---
echo "Checking if Artifact Registry repository '${ARTIFACT_REGISTRY_REPO}' exists in region '${REGION}'..."
if ! gcloud artifacts repositories describe "${ARTIFACT_REGISTRY_REPO}" --project="${GCP_PROJECT_ID}" --location="${REGION}" &> /dev/null; then
    echo "Repository does not exist. Creating '${ARTIFACT_REGISTRY_REPO}' in '${REGION}'..."
    gcloud artifacts repositories create "${ARTIFACT_REGISTRY_REPO}" \
        --repository-format=docker \
        --location="${REGION}" \
        --description="Docker repository for Naturopath Chat application" \
        --project="${GCP_PROJECT_ID}"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create Artifact Registry repository. Please check permissions or create it manually."
        exit 1
    fi
    echo "Artifact Registry repository created successfully."
else
    echo "Artifact Registry repository already exists."
fi


# --- Build the Docker image ---
echo "Building Docker image: $IMAGE_TAG_LATEST (and $IMAGE_TAG_VERSIONED)..."
docker build -t "$IMAGE_TAG_LATEST" -t "$IMAGE_TAG_VERSIONED" .
if [ $? -ne 0 ]; then
    echo "Error: Docker build failed."
    exit 1
fi
echo "Docker image built successfully."

# --- Configure Docker to use gcloud as a credential helper for Artifact Registry ---
echo "Configuring Docker authentication for $REGION-docker.pkg.dev..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
if [ $? -ne 0 ]; then
    echo "Error: Failed to configure Docker authentication."
    exit 1
fi
echo "Docker authentication configured."

# --- Push the Docker image to Artifact Registry ---
echo "Pushing Docker image $IMAGE_TAG_LATEST to Artifact Registry..."
docker push "$IMAGE_TAG_LATEST"
if [ $? -ne 0 ]; then
    echo "Error: Docker push (latest) failed."
    exit 1
fi
echo "Pushing Docker image $IMAGE_TAG_VERSIONED to Artifact Registry..."
docker push "$IMAGE_TAG_VERSIONED"
if [ $? -ne 0 ]; then
    echo "Error: Docker push (versioned) failed."
    exit 1
fi
echo "Docker image pushed successfully to Artifact Registry."

# --- Deploy to Google Cloud Run ---
echo "Deploying image $IMAGE_TAG_LATEST to Cloud Run service $SERVICE_NAME in $REGION..."
gcloud run deploy "$SERVICE_NAME" \
    --image="$IMAGE_TAG_LATEST" \
    --platform=managed \
    --region="$REGION" \
    --allow-unauthenticated \
    --port=8080 \
    --project="$GCP_PROJECT_ID" \
    --quiet 
    # Add --set-env-vars or other flags as needed

if [ $? -ne 0 ]; then
    echo "Error: Deployment to Cloud Run failed."
    exit 1
fi

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --platform=managed --region="$REGION" --format='value(status.url)' --project="$GCP_PROJECT_ID")
echo "------------------------------------------------------------------"
echo "Deployment successful!"
echo "Your application $SERVICE_NAME is available at: $SERVICE_URL"
echo "------------------------------------------------------------------"

# --- End of script ---
