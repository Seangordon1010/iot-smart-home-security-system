#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>
#include <stdbool.h>

#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/task.h"

#include "esp_log.h"
#include "esp_event.h"
#include "esp_netif.h"
#include "esp_wifi.h"
#include "esp_sntp.h"
#include "esp_heap_caps.h"
#include "nvs_flash.h"
#include "esp_camera.h"
#include "esp_http_client.h"
#include "img_converters.h"

#include "device_config.h"

#define WIFI_SSID "HOME-B299-2.4"
#define WIFI_PASSWORD "APUDHN3AHCAJ3W39"

#define SERVER_IMAGE_URL "http://10.0.0.244:3000/api/device/events/image"

#define PWDN_GPIO_NUM -1
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM 15

#define SIOD_GPIO_NUM 4
#define SIOC_GPIO_NUM 5

#define Y9_GPIO_NUM 16
#define Y8_GPIO_NUM 17
#define Y7_GPIO_NUM 18
#define Y6_GPIO_NUM 12
#define Y5_GPIO_NUM 10
#define Y4_GPIO_NUM 8
#define Y3_GPIO_NUM 9
#define Y2_GPIO_NUM 11

#define VSYNC_GPIO_NUM 6
#define HREF_GPIO_NUM 7
#define PCLK_GPIO_NUM 13

#define WIFI_CONNECTED_BIT BIT0

#define FRAME_INTERVAL_MS 1000
#define PIXEL_CHANGE_THRESHOLD 25
#define MOTION_PERCENT_THRESHOLD 20
#define JPEG_QUALITY 80

static const char *TAG = "SECURITY_CAMERA";

static EventGroupHandle_t wifi_event_group;

static uint8_t *previous_frame = NULL;
static size_t previous_frame_size = 0;

static void wifi_event_handler(
    void *arg,
    esp_event_base_t event_base,
    int32_t event_id,
    void *event_data)
{
    if (event_base == WIFI_EVENT &&
        event_id == WIFI_EVENT_STA_START)
    {
        esp_wifi_connect();
    }
    else if (event_base == WIFI_EVENT &&
             event_id == WIFI_EVENT_STA_DISCONNECTED)
    {
        xEventGroupClearBits(wifi_event_group, WIFI_CONNECTED_BIT);

        ESP_LOGW(TAG, "Wi-Fi disconnected. Reconnecting...");
        esp_wifi_connect();
    }
    else if (event_base == IP_EVENT &&
             event_id == IP_EVENT_STA_GOT_IP)
    {
        ip_event_got_ip_t *event =
            (ip_event_got_ip_t *)event_data;

        ESP_LOGI(
            TAG,
            "Wi-Fi connected. ESP32 IP: " IPSTR,
            IP2STR(&event->ip_info.ip)
        );

        xEventGroupSetBits(wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

static void wifi_init(void)
{
    wifi_event_group = xEventGroupCreate();

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(
        esp_event_handler_register(
            WIFI_EVENT,
            ESP_EVENT_ANY_ID,
            wifi_event_handler,
            NULL
        )
    );

    ESP_ERROR_CHECK(
        esp_event_handler_register(
            IP_EVENT,
            IP_EVENT_STA_GOT_IP,
            wifi_event_handler,
            NULL
        )
    );

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = WIFI_SSID,
            .password = WIFI_PASSWORD
        }
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));

    ESP_ERROR_CHECK(
        esp_wifi_set_config(WIFI_IF_STA, &wifi_config)
    );

    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "Connecting to Wi-Fi: %s", WIFI_SSID);

    xEventGroupWaitBits(
        wifi_event_group,
        WIFI_CONNECTED_BIT,
        pdFALSE,
        pdFALSE,
        portMAX_DELAY
    );
}

static void initialize_time(void)
{
    ESP_LOGI(TAG, "Synchronizing time using NTP...");

    esp_sntp_setoperatingmode(SNTP_OPMODE_POLL);
    esp_sntp_setservername(0, "pool.ntp.org");
    esp_sntp_init();

    time_t now = 0;
    struct tm time_info = {0};
    int attempts = 0;

    while (time_info.tm_year < (2024 - 1900) &&
           attempts < 20)
    {
        vTaskDelay(pdMS_TO_TICKS(1000));

        time(&now);
        localtime_r(&now, &time_info);

        attempts++;
    }

    if (time_info.tm_year >= (2024 - 1900))
    {
        ESP_LOGI(TAG, "System time synchronized.");
    }
    else
    {
        ESP_LOGW(TAG, "Time synchronization failed.");
    }
}

static void send_event_with_image(camera_fb_t *frame)
{
    uint8_t *jpeg_buffer = NULL;
    size_t jpeg_length = 0;

    if (!fmt2jpg(
            frame->buf,
            frame->len,
            frame->width,
            frame->height,
            frame->format,
            JPEG_QUALITY,
            &jpeg_buffer,
            &jpeg_length))
    {
        ESP_LOGE(TAG, "Failed to convert camera frame to JPEG.");
        return;
    }

    ESP_LOGI(
        TAG,
        "JPEG image created. Size: %u bytes",
        (unsigned int)jpeg_length
    );

    time_t now;
    struct tm time_info;
    char timestamp[32];

    time(&now);
    gmtime_r(&now, &time_info);

    strftime(
        timestamp,
        sizeof(timestamp),
        "%Y-%m-%dT%H:%M:%SZ",
        &time_info
    );

    const char *boundary = "----ESP32S3Boundary7MA4YWxkTrZu0gW";

    char multipart_header[768];

    int header_length = snprintf(
        multipart_header,
        sizeof(multipart_header),
        "--%s\r\n"
        "Content-Disposition: form-data; name=\"device_id\"\r\n\r\n"
        "ESP32-S3-EYE\r\n"
        "--%s\r\n"
        "Content-Disposition: form-data; name=\"event_type\"\r\n\r\n"
        "motion_detected\r\n"
        "--%s\r\n"
        "Content-Disposition: form-data; name=\"timestamp\"\r\n\r\n"
        "%s\r\n"
        "--%s\r\n"
        "Content-Disposition: form-data; name=\"status\"\r\n\r\n"
        "new\r\n"
        "--%s\r\n"
        "Content-Disposition: form-data; name=\"image\"; filename=\"capture.jpg\"\r\n"
        "Content-Type: image/jpeg\r\n\r\n",
        boundary,
        boundary,
        boundary,
        timestamp,
        boundary,
        boundary
    );

    if (header_length < 0 ||
        (size_t)header_length >= sizeof(multipart_header))
    {
        ESP_LOGE(TAG, "Failed to create multipart request header.");
        free(jpeg_buffer);
        return;
    }

    char multipart_end[80];

    int end_length = snprintf(
        multipart_end,
        sizeof(multipart_end),
        "\r\n--%s--\r\n",
        boundary
    );

    if (end_length < 0 ||
        (size_t)end_length >= sizeof(multipart_end))
    {
        ESP_LOGE(TAG, "Failed to create multipart closing boundary.");
        free(jpeg_buffer);
        return;
    }

    size_t body_length =
        (size_t)header_length + jpeg_length + (size_t)end_length;

    uint8_t *body = malloc(body_length);

    if (body == NULL)
    {
        ESP_LOGE(TAG, "Failed to allocate upload request buffer.");
        free(jpeg_buffer);
        return;
    }

    memcpy(body, multipart_header, (size_t)header_length);

    memcpy(
        body + header_length,
        jpeg_buffer,
        jpeg_length
    );

    memcpy(
        body + header_length + jpeg_length,
        multipart_end,
        (size_t)end_length
    );

    esp_http_client_config_t config = {
        .url = SERVER_IMAGE_URL,
        .method = HTTP_METHOD_POST,
        .timeout_ms = 20000
    };

    esp_http_client_handle_t client =
        esp_http_client_init(&config);

    if (client == NULL)
    {
        ESP_LOGE(TAG, "Failed to initialize HTTP client.");
        free(body);
        free(jpeg_buffer);
        return;
    }

    char content_type[100];

    snprintf(
        content_type,
        sizeof(content_type),
        "multipart/form-data; boundary=%s",
        boundary
    );

    esp_http_client_set_header(
        client,
        "Content-Type",
        content_type
    );

    esp_http_client_set_header(
        client,
        "X-Device-Key",
        DEVICE_API_KEY
    );

    esp_http_client_set_post_field(
        client,
        (const char *)body,
        (int)body_length
    );

    ESP_LOGI(TAG, "Uploading motion event and JPEG image...");

    esp_err_t result = esp_http_client_perform(client);

    if (result == ESP_OK)
    {
        int status_code =
            esp_http_client_get_status_code(client);

        if (status_code == 201)
        {
            ESP_LOGI(
                TAG,
                "Motion event and image successfully saved."
            );
        }
        else
        {
            ESP_LOGE(
                TAG,
                "Backend returned HTTP status: %d",
                status_code
            );
        }
    }
    else
    {
        ESP_LOGE(
            TAG,
            "Image upload failed: %s",
            esp_err_to_name(result)
        );
    }

    esp_http_client_cleanup(client);

    free(body);
    free(jpeg_buffer);
}

static bool detect_motion(
    const uint8_t *current_frame,
    size_t frame_size)
{
    if (previous_frame == NULL ||
        previous_frame_size != frame_size)
    {
        if (previous_frame != NULL)
        {
            free(previous_frame);
            previous_frame = NULL;
        }

        previous_frame = heap_caps_malloc(
            frame_size,
            MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT
        );

        if (previous_frame == NULL)
        {
            ESP_LOGE(
                TAG,
                "Failed to allocate previous frame buffer."
            );

            previous_frame_size = 0;
            return false;
        }

        memcpy(previous_frame, current_frame, frame_size);
        previous_frame_size = frame_size;

        ESP_LOGI(TAG, "Initial frame saved as comparison baseline.");
        return false;
    }

    size_t changed_pixels = 0;

    for (size_t i = 0; i < frame_size; i++)
    {
        int difference =
            abs((int)current_frame[i] - (int)previous_frame[i]);

        if (difference >= PIXEL_CHANGE_THRESHOLD)
        {
            changed_pixels++;
        }
    }

    memcpy(previous_frame, current_frame, frame_size);

    size_t changed_percent =
        (changed_pixels * 100) / frame_size;

    ESP_LOGI(
        TAG,
        "Changed pixels: %u%%",
        (unsigned int)changed_percent
    );

    if (changed_percent >= MOTION_PERCENT_THRESHOLD)
    {
        ESP_LOGI(TAG, "Possible motion detected!");
        return true;
    }

    return false;
}

void app_main(void)
{
    esp_err_t ret = nvs_flash_init();

    if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
        ret == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }

    ESP_ERROR_CHECK(ret);

    wifi_init();
    initialize_time();

    camera_config_t camera_config = {
        .pin_pwdn = PWDN_GPIO_NUM,
        .pin_reset = RESET_GPIO_NUM,
        .pin_xclk = XCLK_GPIO_NUM,

        .pin_sccb_sda = SIOD_GPIO_NUM,
        .pin_sccb_scl = SIOC_GPIO_NUM,

        .pin_d7 = Y9_GPIO_NUM,
        .pin_d6 = Y8_GPIO_NUM,
        .pin_d5 = Y7_GPIO_NUM,
        .pin_d4 = Y6_GPIO_NUM,
        .pin_d3 = Y5_GPIO_NUM,
        .pin_d2 = Y4_GPIO_NUM,
        .pin_d1 = Y3_GPIO_NUM,
        .pin_d0 = Y2_GPIO_NUM,

        .pin_vsync = VSYNC_GPIO_NUM,
        .pin_href = HREF_GPIO_NUM,
        .pin_pclk = PCLK_GPIO_NUM,

        .xclk_freq_hz = 16000000,
        .ledc_timer = LEDC_TIMER_0,
        .ledc_channel = LEDC_CHANNEL_0,

        .pixel_format = PIXFORMAT_GRAYSCALE,
        .frame_size = FRAMESIZE_QVGA,
        .jpeg_quality = 12,
        .fb_count = 1,
        .grab_mode = CAMERA_GRAB_WHEN_EMPTY
    };

    ESP_LOGI(TAG, "Initializing camera...");

    esp_err_t camera_result = esp_camera_init(&camera_config);

    if (camera_result != ESP_OK)
    {
        ESP_LOGE(
            TAG,
            "Camera initialization failed: %s",
            esp_err_to_name(camera_result)
        );

        return;
    }

    ESP_LOGI(TAG, "Camera initialized successfully.");
    ESP_LOGI(TAG, "Starting software motion detection.");

    while (1)
    {
        camera_fb_t *frame = esp_camera_fb_get();

        if (frame == NULL)
        {
            ESP_LOGE(TAG, "Image capture failed.");
        }
        else
        {
            bool motion_detected = detect_motion(
                frame->buf,
                frame->len
            );

            if (motion_detected)
            {
                if (xEventGroupGetBits(wifi_event_group) &
                    WIFI_CONNECTED_BIT)
                {
                    send_event_with_image(frame);
                }
                else
                {
                    ESP_LOGW(
                        TAG,
                        "Motion detected, but Wi-Fi is unavailable."
                    );
                }
            }

            esp_camera_fb_return(frame);
        }

        vTaskDelay(pdMS_TO_TICKS(FRAME_INTERVAL_MS));
    }
}
