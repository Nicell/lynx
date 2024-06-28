import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://lynx.land',
	prefetch: true,
	integrations: [
		starlight({
			title: 'Lynx',
			social: {
				github: 'https://github.com/Nicell/lynx',
			},
			customCss: [
				'./src/style.css'
			],
			sidebar: [
				{
					label: 'Getting Started',
					link: '/getting-started',
				},
				{
					label: 'Reference',
					autogenerate: { directory: 'reference' },
				},
				{
					label: 'Middleware',
					autogenerate: { directory: 'middleware' },
				},
			],
		}),
	],
});
