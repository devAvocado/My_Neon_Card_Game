import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// ==========================================
// CONFIGURACIÓN
// ==========================================
// '.' significa el directorio actual desde donde corres el script
const CARPETA_ENTRADA = '.'; 
const ARCHIVO_SALIDA = './contexto_generado.txt';

// Extensiones de archivos binarios o pesados que no queremos en el contexto
const EXTENSIONES_IGNORADAS = [
    '.png', '.jpg', '.jpeg', '.gif', '.ico', '.pdf', '.zip', '.tar', '.gz', '.mp4', '.mp3', '.ttf', '.woff', '.woff2'
];

// Carpetas críticas que DEBEMOS ignorar para evitar bucles infinitos o basura
const CARPETAS_IGNORADAS = [
    'node_modules', 
    '.git', 
    '.next', 
    'dist', 
    'build', 
    '.turbo', // Por si usas monorrepos
    '.vscode'
];

// ==========================================
// FUNCIÓN RECURSIVA
// ==========================================
function procesarCarpeta(rutaCarpeta, streamSalida) {
    const elementos = fs.readdirSync(rutaCarpeta);

    elementos.forEach(elemento => {
        const rutaCompleta = path.join(rutaCarpeta, elemento);
        const estadisticas = fs.statSync(rutaCompleta);

        if (estadisticas.isDirectory()) {
            // Si es una carpeta y no está en la lista de ignoradas, entramos en ella
            if (!CARPETAS_IGNORADAS.includes(elemento)) {
                procesarCarpeta(rutaCompleta, streamSalida);
            }
        } else if (estadisticas.isFile()) {
            const ext = path.extname(elemento).toLowerCase();
            
            // Validamos que:
            // 1. No sea una extensión ignorada.
            // 2. No sea el propio script que se está ejecutando (a.js).
            // 3. No sea el archivo de salida (contexto_generado.txt).
            const esElPropioScript = elemento === 'a.js';
            const esElArchivoSalida = rutaCompleta === path.resolve(ARCHIVO_SALIDA);

            if (!EXTENSIONES_IGNORADAS.includes(ext) && !esElPropioScript && !esElArchivoSalida) {
                try {
                    const contenido = fs.readFileSync(rutaCompleta, 'utf-8');
                    
                    // Separador visual con la ruta del archivo
                    streamSalida.write(`\n==================================================\n`);
                    streamSalida.write(`ARCHIVO: ${rutaCompleta}\n`);
                    streamSalida.write(`==================================================\n\n`);
                    streamSalida.write(contenido);
                    streamSalida.write('\n');
                    
                    console.log(`✔ Procesado: ${rutaCompleta}`);
                } catch (error) {
                    console.error(`❌ Error al leer ${rutaCompleta}:`, error.message);
                }
            }
        }
    });
}

function iniciar() {
    console.log(`🚀 Escaneando el directorio actual y todas sus subcarpetas...`);

    const streamSalida = fs.createWriteStream(ARCHIVO_SALIDA, { encoding: 'utf-8' });

    streamSalida.on('open', () => {
        procesarCarpeta(CARPETA_ENTRADA, streamSalida);
        streamSalida.end();
    });

    streamSalida.on('finish', () => {
        console.log(`\n✨ ¡Listo! Contexto completo generado en: ${ARCHIVO_SALIDA}`);
    });

    streamSalida.on('error', (err) => {
        console.error('❌ Error al escribir el archivo de salida:', err);
    });
}

iniciar();