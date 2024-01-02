import { makeEnvPublic } from 'next-runtime-env';

export function register() {
  makeEnvPublic([
    'NEXT_PUBLIC_WEBAPP_URL',
    
  ]);
}