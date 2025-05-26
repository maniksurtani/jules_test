# Naturopath Chat - Virtual Naturopath Website

This project aims to build a responsive website presenting a virtual naturopath, providing naturopathy advice to peoples' queries.

## Plan

The project was implemented following these main steps:

1.  *Set up the project structure:*
    - Create a root directory for the project (`naturopath_chat`).
    - Create a `README.md` file.
    - Set up a basic HTML file (`templates/index.html`) to include Semantic UI from a CDN.
    - Create directories for static assets (`static/css`, `static/js`, `static/images`).
    - Create a basic Python Flask app file (`app.py`).
2.  *Design the UI (Semantic UI):*
    - Choose a comforting and pleasing color scheme.
    - Plan the layout using Semantic UI components (Grid, Card, Comments, Form).
    - Use a placeholder icon for "Dr Tina's" avatar.
    - Design the chat interface elements.
3.  *Implement the Front-End (Semantic UI & JavaScript):*
    - Implement the layout and color scheme in `index.html` and `static/css/custom.css`.
    - Add the Dr Tina avatar (icon) to the UI.
    - Implement the chat interface in `index.html` and `static/js/chat.js`, enabling users to send messages and see them displayed.
4.  *Implement the Back-End (Python Flask):*
    - In `app.py`, create a Flask application.
    - Define a `/chat` route that accepts POST requests with user messages (JSON).
    - Implement basic logic in the backend to generate responses (e.g., echo, keyword-based).
    - The frontend JavaScript was updated to communicate with this Flask backend.
5.  *Create helper scripts:*
    - Write a `run_dev.sh` script to easily run the Flask development server locally.
    - Research and document deployment options in the README.
6.  *Documentation:*
    - Ensure the `README.md` is updated and accurately reflects the project.

## Technology Stack

-   **Front-End:** HTML, CSS, JavaScript, Semantic UI
-   **Back-End:** Python (Flask)
-   **Containerization:** Docker
-   **Deployment:** Google Cloud Run
-   **Development Scripting:** Bash (for `run_dev.sh`)

## Getting Started

### Prerequisites
- Python 3.x
- pip (Python package installer)
- Flask (`pip install Flask`)
- Gunicorn (`pip install gunicorn`)
- Google Generative AI SDK (`pip install google-generativeai`)
- This is a `uv` managed Python environment. Ensure `uv` is installed using your system's package manager (e.g., HomeBrew, rpm, apt, etc.), then start with `$ uv venv` and `$ uv pip install -r requirements.txt`

### Gemini API Key for LLM Responses

To enable intelligent chat responses, this application uses the Google Gemini API. You will need to obtain an API key from Google AI Studio ([https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)) and set it as an environment variable:

```bash
export GEMINI_API_KEY="YOUR_ACTUAL_API_KEY"
```

Make sure this environment variable is set in your local development environment and configured appropriately for your Google Cloud Run deployment (e.g., via Secret Manager or directly as an environment variable in the Cloud Run service settings). Without this key, the chat functionality requiring the LLM will not work.

### Running Locally
1. Clone this repository (if applicable).
2. Set up `uv` as described in Prerequesites.
3. Navigate to the `naturopath_chat` directory.
4. Make the development script executable: `chmod +x run_dev.sh`
5. Run the development server: `./run_dev.sh`
6. Open your web browser and go to `http://127.0.0.1:5000`.

## Deployment

The recommended method for deploying this application is using **Google Cloud Run**. While other platforms (like Heroku, PythonAnywhere, or traditional VPS) can also host Flask applications, Google Cloud Run provides a scalable, serverless environment that integrates well with containerized applications.

### Prerequisites for Google Cloud Run Deployment

1.  **Google Cloud Platform (GCP) Account:** You'll need an active GCP account with billing enabled.
2.  **Google Cloud SDK:** Install and initialize the Google Cloud SDK ([https://cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)). This will provide the `gcloud` command-line tool.
    *   After installation, authenticate and configure your project:
        ```bash
        gcloud auth login
        gcloud config set project YOUR_GCP_PROJECT_ID
        ```
3.  **Docker:** Install Docker Desktop or Docker Engine on your local machine ([https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)). It's needed to build the container image.
4.  **Enable APIs:** Ensure the Cloud Build API, Cloud Run API, and Artifact Registry API (or Container Registry API) are enabled in your GCP project. You can do this via the GCP console or `gcloud services enable`:
    ```bash
    gcloud services enable cloudbuild.googleapis.com run.googleapis.com artifactregistry.googleapis.com containerregistry.googleapis.com
    ```

### Deployment Steps using `deploy_cloud_run.sh`

A script `deploy_cloud_run.sh` (to be created in the project root) is provided to simplify the deployment process.

1.  **Make the script executable:**
    ```bash
    chmod +x deploy_cloud_run.sh
    ```
2.  **Run the script:**
    ```bash
    ./deploy_cloud_run.sh
    ```
3.  The script will guide you through:
    *   Setting your GCP Project ID (if not already set).
    *   Defining a service name for your Cloud Run application.
    *   Choosing a region for your deployment.
    *   Building the Docker image.
    *   Pushing the image to Google Artifact Registry (or Google Container Registry).
    *   Deploying the image to Google Cloud Run.
4.  Once deployed, the script will output the URL of your live application.

### Manual Deployment Steps (alternative to script)

If you prefer to run the steps manually:

1.  **Build the Docker image:**
    ```bash
    docker build -t gcr.io/YOUR_GCP_PROJECT_ID/naturopath-chat:latest .
    ```
    (Replace `YOUR_GCP_PROJECT_ID` and `naturopath-chat` as needed. If using Artifact Registry, the tag will be different, e.g., `YOUR_REGION-docker.pkg.dev/YOUR_PROJECT_ID/YOUR_REPO/naturopath-chat:latest`)
2.  **Configure Docker to use `gcloud` as a credential helper:**
    ```bash
    gcloud auth configure-docker
    ```
    (Or for specific regions if using Artifact Registry: `gcloud auth configure-docker YOUR_REGION-docker.pkg.dev`)
3.  **Push the image:**
    ```bash
    docker push gcr.io/YOUR_GCP_PROJECT_ID/naturopath-chat:latest
    ```
    (Adjust tag for Artifact Registry if used)
4.  **Deploy to Cloud Run:**
    ```bash
    gcloud run deploy naturopath-chat-service \
        --image gcr.io/YOUR_GCP_PROJECT_ID/naturopath-chat:latest \
        --platform managed \
        --region YOUR_GCP_REGION \
        --allow-unauthenticated \
        --port 8080 \
        --set-env-vars GEMINI_API_KEY="YOUR_ACTUAL_API_KEY_HERE"
        # For better security, consider using Google Secret Manager:
        # --update-secrets=GEMINI_API_KEY=YOUR_SECRET_NAME:latest
    ```
    (Replace `naturopath-chat-service`, `YOUR_GCP_PROJECT_ID`, `YOUR_GCP_REGION`, and `YOUR_ACTUAL_API_KEY_HERE` as needed. `--allow-unauthenticated` makes the service public.)
