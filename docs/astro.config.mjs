import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import luau from './Luau.tmLanguage.json'


// https://astro.build/config
export default defineConfig({
	site: 'https://lynx.land',
	prefetch: true,
	markdown:{
		shikiConfig: {
			langs: [luau],
		}
	},
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
