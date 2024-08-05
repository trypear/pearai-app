module.exports = {
	"parserOptions": {
		"tsconfigRootDir": __dirname,
		"project": "./tsconfig.json"
	},
	"rules": {
		'no-console': 'warn', // or 'error'
		"@typescript-eslint/prefer-optional-chain": "warn",
		"@typescript-eslint/prefer-readonly": "warn"
	}
};
