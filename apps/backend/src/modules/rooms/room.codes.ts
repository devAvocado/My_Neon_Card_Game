const WORDS = [
  'NEON', 'TOXIC', 'SHADOW', 'COBRA', 'FROST', 'STORM',
  'VOID', 'BLAZE', 'NOVA', 'OMEGA', 'PULSE', 'RAVEN',
  'APEX', 'ZERO', 'CHAOS', 'VIPER',
]

/** Genera un código de sala tipo NEON-8421 */
export function generateRoomCode(): string {
  const word = WORDS[Math.floor(Math.random() * WORDS.length)] ?? 'NEON'
  const num = Math.floor(1000 + Math.random() * 9000)
  return `${word}-${num}`
}

/** Valida formato de código de sala */
export function isValidRoomCode(code: string): boolean {
  return /^[A-Z]{3,8}-\d{4}$/.test(code)
}
