# Despliegue de la aplicacion con Docker y Kubernetes

Aplicacion de **gestion de usuarios**: un backend (Spring Boot, Java 21) y un frontend (app Flutter compilada para web y servida con nginx). Cada parte se contenieriza con Docker y se despliega en Kubernetes (Docker Desktop). El backend corre con **2 replicas** y se escala a **5**.

## Arquitectura

```
Navegador -> Service usuarios-frontend (LoadBalancer, puerto 80)
          -> Pod nginx (frontend)
          -> Service usuarios-backend (ClusterIP, puerto 8080)
          -> Pods del backend (2 replicas, luego 5)
          -> Base de datos PostgreSQL
```

- El navegador solo habla con nginx. nginx sirve la app Flutter y reenvia al backend las rutas `/auth`, `/api`, `/upload` y `/notifications`. Asi no hay problemas de CORS.
- El backend no se expone al exterior: su Service es `ClusterIP`.
- Las claves se guardan en un **Secret** de Kubernetes y nunca en archivos del repositorio.

## Estructura relevante

```
backend/     Spring Boot + Dockerfile (dos etapas: compila con Maven y ejecuta con JRE)
frontend/    Dockerfile (nginx), nginx.conf y web/ (app Flutter compilada)
mobile/      Codigo fuente Flutter (la misma app, version movil y web)
k8s/         backend-deployment.yaml, backend-service.yaml,
             frontend-deployment.yaml, frontend-service.yaml
```

## Requisitos

- Docker Desktop con Kubernetes activado (contexto `docker-desktop`)
- kubectl
- Flutter (solo para recompilar la version web)

## 1. Construir la imagen del backend

```powershell
docker build -t usuarios-backend:1.0 ./backend
```

## 2. Compilar el frontend para web y construir su imagen

La URL del backend se define al compilar con `--dart-define`. Si no se indica, la app movil usa la URL de AWS por defecto.

```powershell
cd mobile
flutter build web --release --dart-define=API_URL=http://localhost
cd ..
Copy-Item -Path mobile\build\web -Destination frontend\web -Recurse
docker build -t usuarios-frontend:1.0 ./frontend
```

Si `frontend\web` ya existe, borrarla antes de copiar: `Remove-Item frontend\web -Recurse -Force`.

## 3. Base de datos

Para las pruebas se usa el PostgreSQL local definido en `backend/docker-compose.yml` (solo el servicio `db`):

```powershell
cd backend
docker compose up -d db
cd ..
```

Los pods llegan a esa base a traves de `host.docker.internal:5433`.

## 4. Crear el Secret

Las variables se escriben en la terminal (nunca en archivos del repositorio):

```powershell
$env:DB_URL = "jdbc:postgresql://host.docker.internal:5433/usuarios_db"
$env:DB_USER = Read-Host "DB_USER"
$env:DB_PASSWORD = Read-Host "DB_PASSWORD"
$env:JWT_SECRET = [Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }))

kubectl create secret generic usuarios-secrets "--from-literal=DB_URL=$env:DB_URL" "--from-literal=DB_USER=$env:DB_USER" "--from-literal=DB_PASSWORD=$env:DB_PASSWORD" "--from-literal=JWT_SECRET=$env:JWT_SECRET"
```

## 5. Desplegar

```powershell
kubectl apply -f k8s/
kubectl rollout status deployment/usuarios-backend --timeout=180s
kubectl rollout status deployment/usuarios-frontend --timeout=120s
kubectl get pods
kubectl get deployments
kubectl get svc
```

La aplicacion queda disponible en **http://localhost**.

## 6. Escalar el backend de 2 a 5 replicas

```powershell
kubectl scale deployment usuarios-backend --replicas=5
kubectl get pods
kubectl rollout status deployment/usuarios-backend --timeout=180s
kubectl get deployments
```

Tambien se puede cambiar `replicas: 5` en `k8s/backend-deployment.yaml` y ejecutar `kubectl apply -f k8s/`.

## 7. Limpieza

```powershell
kubectl delete -f k8s/
kubectl delete secret usuarios-secrets
docker compose -f backend/docker-compose.yml down
```

## Notas y limitaciones

- El backend necesita la variable `AWS_REGION` (no secreta, definida en el Deployment) porque crea un cliente de AWS SNS al arrancar.
- Dentro del contenedor no hay credenciales de AWS, por lo que las funciones que dependen de AWS (subir archivos a S3 y publicar notificaciones en SNS) no funcionan en este despliegue. El registro, el inicio de sesion y la gestion de usuarios si funcionan.
- Las imagenes son locales (`imagePullPolicy: IfNotPresent`), por lo que este despliegue esta pensado para el Kubernetes de Docker Desktop.
- La base de datos del despliegue es un PostgreSQL local de pruebas, distinta de la que usa la aplicacion movil en AWS.
- Las evidencias (capturas) estan en el PDF de la entrega.