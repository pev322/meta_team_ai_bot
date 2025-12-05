# META Assistant AI

An AI assistant for public services with an offline-first architecture.



## Features

-   **Universal**: Supports Web, Android, and iOS.
-   **Offline-first**: 90% of requests are processed locally without an internet connection.
-   **Multilingual**: French and Arabic language support (with RTL).
-   **Low requirements**: Works on low-end devices and slow internet connections.
-   **Multi-level processing**: Rules → FAQ → Local AI → Online API.

## Demo

Watch the project presentation on YouTube:

[![META Assistant AI Demo](https://img.youtube.com/vi/wEph9VzEjhU/0.jpg)](https://youtu.be/wEph9VzEjhU)

[Watch on YouTube](https://youtu.be/wEph9VzEjhU)

## Quick Start

### Prerequisites

-   Flutter SDK >= 3.8.1
-   Dart SDK >= 3.8.1

### Installation

1.  **Install dependencies**

    ```bash
    flutter pub get
    ```

2.  **Generate Hive adapters**

    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

3.  **Run the application**

    For Web:

    ```bash
    flutter run -d chrome
    ```

    For Android/iOS:

    ```bash
    flutter run
    ```

## Architecture

The application uses a 4-level cascade system for processing requests, where each subsequent level is activated only if the previous one was unable to provide an answer. This ensures an optimal balance between speed, accuracy, and offline availability.

1.  **Rule-based Service**: Handles simple queries based on keywords.
2.  **FAQ Search Service**: Performs a search on a local database of frequently asked questions.
3.  **Local AI Service**: Uses a local TFLite model (DistilBERT) for question answering.
4.  **Online API Service**: A fallback to an online API for complex queries.

### Current Status

-   **Level 4 (Online API)**: Can be connected but is currently **not configured**. To enable it, you need to set up the API endpoint in the configuration.
-   **Level 3 (Local AI)**: A test model is available, but it is quite **weak** due to lack of GPU resources for training a more powerful model.
-   **Web Version**: Level 3 (Local AI) does **not work** in the web version. Only levels 1, 2, and 4 are available for web deployments.

## AI Model

The project uses a DistilBERT model for question answering.

### Model Setup

⚠️ **Important**: The model is **not included** in the repository by default due to its large size.

To use the Local AI Service (Level 3), you need to:

1.  Generate or obtain the TFLite model file
2.  Place it in: `assets/models/model.tflite`

To generate the model, you can use the scripts in the `ai_model_maker` directory.

### Model Limitations

⚠️ **Important Notes**:

-   The current local AI model (Level 3) is a **test version** with limited capabilities.
-   Due to lack of GPU resources, we were unable to train a more powerful model.
-   The model works on **Android and iOS** platforms but **not on Web**.
-   For better accuracy on complex queries, consider configuring the **Online API** (Level 4).

## Web Widget Integration

You can integrate the AI assistant as a widget on any website by adding the following code to your HTML:

```html
<div id="meta-ai-widget-wrapper" style="
    position: fixed;
    bottom: 0;
    right: 0;
    z-index: 2147483647;
    width: 80px;
    height: 80px;
    transition: width 0s, height 0s;
">
    <iframe
        id="meta-ai-iframe"
        src="https://pev-works.com/meta-bot-ai/chat_widget.html"
        style="
            width: 100%;
            height: 100%;
            border: none;
            background: transparent;
        "
        allowtransparency="true"
    ></iframe>
</div>

<script>
    (function() {
        const wrapper = document.getElementById('meta-ai-widget-wrapper');

        window.addEventListener('message', function(event) {

            if (event.data === 'meta-ai-chat-open') {
                wrapper.style.width = '380px';
                wrapper.style.height = '700px';
                if (window.innerWidth < 480) {
                    wrapper.style.width = '100vw';
                    wrapper.style.height = '100vh';
                }
            }
            else if (event.data === 'meta-ai-chat-close') {
                wrapper.style.width = '80px';
                wrapper.style.height = '80px';
            }
        });
    })();
</script>
```

This will add a floating widget to the bottom-right corner of your website. The widget automatically expands when opened and collapses when closed, with responsive support for mobile devices.

## Build for production

```bash
# Web
flutter build web --release

# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Author

**Yevhenii POBEDYNSKYI**
[pev-works.com](https://pev-works.com)
