# TFG MyNgo - Send Photos in Chat
Status: ✅ Backend Complete

## Breakdown Steps (Sequential)

### 1. Backend Updates ✅ Done
- [x] Edit `backend/myngo_api/apps/mensajeria/views.py`: Add `upload_chat_image` view using `ImagenGaleria` with S3 'chats/contenido'
- [x] Edit `backend/myngo_api/apps/mensajeria/urls.py`: Add route for upload
- [x] Edit `backend/myngo_api/apps/mensajeria/consumers.py`: Update `save_message` for `tipo`, `url_archivo_s3`, WS receive/group_send

### 2. Frontend Service
- [ ] Edit `frontend/myngo_app/lib/services/servicio_mensajeria.dart`: Add `uploadChatImage`

### 3. Frontend UI/Model
- [ ] Edit `frontend/myngo_app/lib/models/mensaje_chat.dart`: Ensure image fields
- [ ] Edit `frontend/myngo_app/lib/screens/mensajeria/pantalla_chat.dart`: Add image button, upload+WS send, image display UI

### 4. Testing & Polish
- [ ] Test full flow: pick → upload → WS → display
- [ ] Add l10n: 'Send photo', 'Image uploaded'
- [ ] Backend restart, Flutter hot reload

Next step auto-tracked here.
