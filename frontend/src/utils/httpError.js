const HTTP_STATUS_MESSAGES = {
  400: 'Bad Request (400): The server could not understand or process the request.',
  401: 'Unauthorized (401): Authentication failed or your session has expired.',
  403: 'Forbidden (403): You do not have permission to access this resource.',
  404: 'Not Found (404): The requested resource or endpoint was not found.',
  405: 'Method Not Allowed (405): The HTTP request method is not allowed for this endpoint.',
  408: 'Request Timeout (408): The server timed out waiting for the request.',
  409: 'Conflict (409): The request conflicts with the current state of the resource.',
  413: 'Payload Too Large (413): The uploaded data exceeds the server limit.',
  415: 'Unsupported Media Type (415): The request content type is not supported.',
  419: 'Session Expired (419): Your session or security token has expired. Please refresh and try again.',
  422: 'Unprocessable Content (422): One or more submitted fields are invalid.',
  429: 'Too Many Requests (429): Too many attempts. Please wait a moment and try again.',
  500: 'Internal Server Error (500): An unexpected error occurred on the server.',
  502: 'Bad Gateway (502): The gateway received an invalid response from the upstream server.',
  503: 'Service Unavailable (503): The server is temporarily unavailable. Please try again later.',
  504: 'Gateway Timeout (504): The upstream server did not respond in time.',
}

function extractValidationError(data) {
  if (!data || typeof data !== 'object' || !data.errors || typeof data.errors !== 'object') {
    return null
  }

  for (const fieldErrors of Object.values(data.errors)) {
    if (Array.isArray(fieldErrors)) {
      const first = fieldErrors.find((msg) => typeof msg === 'string' && msg.trim())
      if (first) return first.trim()
    } else if (typeof fieldErrors === 'string' && fieldErrors.trim()) {
      return fieldErrors.trim()
    }
  }

  return null
}

function extractBackendMessage(data) {
  if (!data || typeof data !== 'object') {
    return null
  }

  if (typeof data.message === 'string' && data.message.trim()) {
    return data.message.trim()
  }

  return null
}

/**
 * Return the standard HTTP response description for an HTTP error status code.
 */
export function getHttpStatusMessage(status, statusText = '') {
  if (HTTP_STATUS_MESSAGES[status]) {
    return HTTP_STATUS_MESSAGES[status]
  }

  const label = typeof statusText === 'string' ? statusText.trim() : ''
  if (status >= 400 && status < 500) {
    return `Client Error (${status}): ${label || 'The request could not be processed.'}`
  }

  if (status >= 500) {
    return `Server Error (${status}): ${label || 'An unexpected error occurred on the server.'}`
  }

  return null
}

/**
 * Resolve a user-facing error message from an Axios error, preferring
 * structured JSON backend messages and falling back to standard HTTP meanings.
 */
export function getApiErrorMessage(err, fallback = 'An unexpected error occurred.') {
  if (!err?.response) {
    if (err?.code === 'ECONNABORTED' || /timeout/i.test(err?.message || '')) {
      return HTTP_STATUS_MESSAGES[408]
    }
    if (typeof navigator !== 'undefined' && navigator.onLine === false) {
      return 'Network Offline: No internet connection detected. Please check your network.'
    }
    return 'Network Error: Unable to reach the API server. Please verify the API URL, server status, or CORS configuration.'
  }

  const { status, statusText, data } = err.response
  const validationMessage = extractValidationError(data)
  if (validationMessage) {
    return validationMessage
  }

  const backendMessage = extractBackendMessage(data)
  if (backendMessage) {
    return backendMessage
  }

  return getHttpStatusMessage(status, statusText) || fallback
}

