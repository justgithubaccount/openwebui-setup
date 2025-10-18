# Open WebUI Setup с внешними AI API

Простая настройка Open WebUI с поддержкой внешних AI провайдеров (OpenAI, Anthropic Claude, Google Gemini и других) с автоматическим HTTPS через Caddy.

## Возможности

- **Множество AI провайдеров**: OpenAI, Anthropic Claude, Google Gemini, Azure OpenAI, Groq, Mistral, Cohere
- **Автоматический HTTPS**: Let's Encrypt сертификаты через Caddy
- **Web поиск**: Интеграция с DuckDuckGo или SearXNG
- **Безопасность**: Аутентификация, HTTPS, безопасные заголовки
- **Простая установка**: Интерактивный скрипт настройки

## Предварительные требования

1. **Docker** и **Docker Compose** установлены
   ```bash
   # Проверка
   docker --version
   docker compose version
   ```

2. **Домен** с настроенной DNS записью, указывающей на ваш сервер
   - Создайте A-запись: `chat.example.com` → `IP_вашего_сервера`

3. **Открытые порты**:
   - `80/tcp` - для HTTP (редирект на HTTPS)
   - `443/tcp` - для HTTPS

4. **API ключи** от минимум одного AI провайдера:
   - [OpenAI](https://platform.openai.com/api-keys)
   - [Anthropic](https://console.anthropic.com/)
   - [Google AI Studio](https://makersuite.google.com/app/apikey)
   - [Groq](https://console.groq.com/)
   - Другие по желанию

## Быстрый старт

### Вариант 1: Интерактивная установка (рекомендуется)

```bash
# Запустите скрипт установки
chmod +x start.sh
./start.sh
```

Скрипт запросит:
- Ваш домен
- API ключи провайдеров
- Настройки регистрации пользователей

### Вариант 2: Ручная настройка

1. **Скопируйте пример .env**
   ```bash
   cp .env.example .env
   ```

2. **Отредактируйте .env**
   ```bash
   nano .env
   ```

   Обязательно настройте:
   ```env
   # Ваш домен
   DOMAIN=chat.example.com

   # Минимум один API ключ
   OPENAI_API_KEY=sk-...
   # или
   ANTHROPIC_API_KEY=sk-ant-...
   # или
   GOOGLE_API_KEY=...

   # Сгенерируйте секретный ключ
   WEBUI_SECRET_KEY=$(openssl rand -hex 32)
   ```

3. **Создайте директорию для данных**
   ```bash
   mkdir -p data
   ```

4. **Запустите сервисы**
   ```bash
   docker compose up -d
   ```

5. **Проверьте статус**
   ```bash
   docker compose ps
   docker compose logs -f
   ```

## Конфигурация

### Структура файлов

```
.
├── docker-compose.yaml    # Конфигурация Docker
├── Caddyfile             # Настройки reverse proxy
├── .env                  # Переменные окружения (ваша конфигурация)
├── .env.example          # Шаблон конфигурации
├── start.sh              # Скрипт автоматической установки
└── data/                 # Данные приложения (создаётся автоматически)
```

### Основные переменные окружения

#### Обязательные

```env
DOMAIN=chat.example.com                    # Ваш домен
WEBUI_SECRET_KEY=<32+ случайных символов> # Секретный ключ
```

#### AI Провайдеры (минимум один)

```env
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=...
GROQ_API_KEY=gsk_...
MISTRAL_API_KEY=...
COHERE_API_KEY=...
```

#### Azure OpenAI

```env
AZURE_OPENAI_API_KEY=...
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4
AZURE_OPENAI_API_VERSION=2024-02-15-preview
```

#### Безопасность

```env
WEBUI_AUTH=true              # Включить аутентификацию
ENABLE_SIGNUP=true           # Разрешить регистрацию
DEFAULT_USER_ROLE=pending    # Роль новых пользователей (pending/user/admin)
```

#### Web поиск

```env
ENABLE_RAG_WEB_SEARCH=true
RAG_WEB_SEARCH_ENGINE=duckduckgo
RAG_WEB_SEARCH_RESULT_COUNT=3
```

## Использование

### Первый запуск

1. Откройте браузер и перейдите на `https://ваш-домен.com`
2. **Первый зарегистрированный пользователь становится администратором**
3. Создайте свой аккаунт
4. Начните общаться с AI!

### Управление

```bash
# Просмотр логов
docker compose logs -f

# Просмотр логов конкретного сервиса
docker compose logs -f open-webui
docker compose logs -f caddy

# Остановка
docker compose down

# Перезапуск
docker compose restart

# Обновление до последней версии
docker compose pull
docker compose up -d

# Полная остановка с удалением данных
docker compose down -v  # ОСТОРОЖНО: удалит все данные!
```

### Резервное копирование

```bash
# Бэкап данных
tar -czf backup-$(date +%Y%m%d).tar.gz data/

# Восстановление
tar -xzf backup-20240101.tar.gz
```

## Устранение неполадок

### Проблема: Caddy не может получить SSL сертификат

**Решение:**
1. Убедитесь, что домен правильно настроен (DNS A-запись)
2. Проверьте, что порты 80 и 443 открыты
3. Проверьте логи: `docker compose logs caddy`

```bash
# Проверка DNS
dig chat.example.com +short

# Проверка портов
sudo netstat -tlnp | grep -E ':(80|443)'
```

### Проблема: Open WebUI не запускается

**Решение:**
1. Проверьте логи: `docker compose logs open-webui`
2. Убедитесь, что указан хотя бы один API ключ
3. Проверьте правильность API ключей

### Проблема: AI не отвечает

**Решение:**
1. Проверьте валидность API ключей
2. Убедитесь, что у вас есть кредиты/доступ к API
3. Проверьте настройки в интерфейсе Open WebUI (Settings → Connections)

### Проблема: "WEBUI_SECRET_KEY not secure"

**Решение:**
```bash
# Сгенерируйте новый ключ
openssl rand -hex 32

# Обновите в .env
nano .env
# Вставьте новый ключ в WEBUI_SECRET_KEY=

# Перезапустите
docker compose restart
```

## Безопасность

### Рекомендации

1. **Секретный ключ**: Используйте уникальный случайный ключ минимум 32 символа
2. **API ключи**: Храните в .env, никогда не коммитьте в git
3. **Регистрация**: Установите `DEFAULT_USER_ROLE=pending` для модерации новых пользователей
4. **HTTPS**: Всегда используйте HTTPS в продакшене (Caddy делает это автоматически)
5. **Обновления**: Регулярно обновляйте образы Docker

### Файрвол

```bash
# UFW пример
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## Дополнительные возможности

### Отключение регистрации после создания аккаунтов

```env
# В .env
ENABLE_SIGNUP=false
```

```bash
docker compose restart
```

### SMTP для email уведомлений

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_USE_TLS=true
```

### Использование SearXNG вместо DuckDuckGo

```env
RAG_WEB_SEARCH_ENGINE=searxng
SEARXNG_QUERY_URL=http://your-searxng:8080/search?q=<query>
```

## Производительность

### Системные требования

**Минимальные:**
- 2 CPU cores
- 4 GB RAM
- 10 GB дисковое пространство

**Рекомендуемые:**
- 4+ CPU cores
- 8+ GB RAM
- 50+ GB SSD

### GPU поддержка (опционально)

Если вы планируете запускать локальные модели:

```yaml
# Раскомментируйте в docker-compose.yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

## Поддержка

- **Документация Open WebUI**: https://docs.openwebui.com
- **GitHub Issues**: https://github.com/open-webui/open-webui/issues
- **Discord**: https://discord.gg/5rJgQTnV4s

## Лицензия

Этот проект использует Open WebUI, который распространяется под MIT лицензией.

---

**Создано для упрощения деплоя Open WebUI с внешними AI провайдерами**
