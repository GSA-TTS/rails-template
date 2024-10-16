import { I18n } from 'i18n-js';
import translations from './generated/translations.json';

const userLocale = document.documentElement.lang;

export const i18n = new I18n();

i18n.store(translations);
i18n.defaultLocale = "en";
i18n.enableFallback = true;
i18n.locale = userLocale;
