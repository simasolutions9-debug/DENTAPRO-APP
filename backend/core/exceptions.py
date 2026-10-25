from rest_framework import status
from rest_framework.views import exception_handler


SPANISH_ERRORS = {
    status.HTTP_401_UNAUTHORIZED: "Autenticación requerida o token no válido.",
    status.HTTP_403_FORBIDDEN: "No tienes permiso para realizar esta acción.",
    status.HTTP_404_NOT_FOUND: "El recurso solicitado no existe.",
    status.HTTP_405_METHOD_NOT_ALLOWED: "Este método no está permitido.",
    status.HTTP_429_TOO_MANY_REQUESTS: "Demasiadas solicitudes. Inténtalo más tarde.",
}


def spanish_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None and response.status_code == status.HTTP_400_BAD_REQUEST:
        fields = list(response.data.keys()) if isinstance(response.data, dict) else []
        response.data = {
            "detail": "La solicitud contiene datos inválidos.",
            "fields": fields,
        }
    elif response is not None and response.status_code in SPANISH_ERRORS:
        response.data = {"detail": SPANISH_ERRORS[response.status_code]}
    return response
