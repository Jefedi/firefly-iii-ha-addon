# Firefly III — Home Assistant Add-on

Gestionnaire de budget personnel self-hosté. Basé sur l'image Docker officielle `fireflyiii/core`, avec SQLite et aucune dépendance externe.

## Fonctionnalités

- 📊 Suivi des dépenses et revenus
- 🐷 Cagnottes (piggy banks) pour tes objectifs (voiture, vacances, animal)
- 📈 Graphiques et statistiques
- 📱 Interface mobile responsive
- 💾 SQLite — zéro dépendance externe (pas de MySQL/MariaDB requis)
- 🔒 100% self-hosté, tes données restent sur ton HA

## Installation

1. Dans Home Assistant : **Paramètres → Add-ons → Boutique d'add-ons → ⋮ → Dépôts**
2. Ajouter : `https://github.com/Jefedi/firefly-iii-ha-addon`
3. Recharger la boutique
4. Installer **Firefly III**
5. Démarrer l'add-on
6. Accéder via `http://[IP_HA]:8080`

## Configuration

| Option | Type | Défaut | Description |
|--------|------|--------|-------------|
| ssl | bool | false | Activer le SSL |
| certfile | str | fullchain.pem | Certificat SSL |
| keyfile | str | privkey.pem | Clé SSL |

## Persistance

Les données (base SQLite, uploads, APP_KEY) sont stockées dans `/data` du conteneur, qui est le volume persistant géré par Home Assistant. Une réinstallation de l'add-on ne perd pas les données.

## Architecture

- **amd64** et **aarch64** supportés
- Basé sur `fireflyiii/core:latest` (PHP 8.2 + nginx)
- s6-overlay pour la compatibilité HA
- SQLite par défaut

## Support

[Issues GitHub](https://github.com/Jefedi/firefly-iii-ha-addon/issues)