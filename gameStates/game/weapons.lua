local weapons = {}

weapons.pistol = {
    name = "Pistol",
    damage = 60,
    projectileSpeed = 0.4,
    projectilesPerShot = 1,
    fireRate = 4,

    spread = 0.1,
    shotSpread = 0.1,
    dashSpread = 0.2,
    movementSpread = 0.04,

    speedFactor = 1.1,
    canAim = true,
    isAuto = false,

    ammo = 12,
    maxAmmo = 12,
    reloadTime = 0.5,
    backupAmmo = 36,
    maxBackupAmmo = 60,
}

weapons.lmg = {
    name = "LMG",
    damage = 30,
    projectileSpeed = 0.35,
    projectilesPerShot = 1,
    fireRate = 14,

    spread = 0.1,
    shotSpread = 0.067,
    dashSpread = 0.6,
    movementSpread = 0.03,

    speedFactor = 0.8,
    canAim = true,
    isAuto = true,

    ammo = 100,
    maxAmmo = 30,
    reloadTime = 2,
    backupAmmo = 100,
    maxBackupAmmo = 90,
}

weapons.smg = {        
    name = "SMG",
    damage = 30,
    projectileSpeed = 0.35,
    projectilesPerShot = 1,
    fireRate = 12,

    spread = 0.2,
    shotSpread = 0.10,
    dashSpread = 0.2,
    movementSpread = 0.03,

    speedFactor = 1,
    canAim = true,
    isAuto = true,

    ammo = 30,
    maxAmmo = 30,
    reloadTime = 0.7,
    backupAmmo = 90,
    maxBackupAmmo = 90,
}

weapons.shotgun = {
    name = "Shotgun",
    damage = 10,
    projectileSpeed = 0.3,
    projectilesPerShot = 12,
    fireRate = 0.5,

    spread = 0.4,
    shotSpread = 0.2,
    dashSpread = 0.3,
    movementSpread = 0.05,

    speedFactor = 0.9,
    canAim = false,
    isAuto = false,

    ammo = 6,
    maxAmmo = 6,
    reloadTime = 1.5,
    backupAmmo = 24,
    maxBackupAmmo = 24,
}

weapons.sawnoff = {
    name = "Sawn Off Shotgun",
    damage = 8,
    projectileSpeed = 0.3,
    projectilesPerShot = 16,
    fireRate = 8,

    spread = 0.6,
    shotSpread = 0.2,
    dashSpread = 0,
    movementSpread = 0.05,

    speedFactor = 1,
    canAim = false,
    isAuto = false,

    ammo = 2,
    maxAmmo = 2,
    reloadTime = 1,
    backupAmmo = 18,
    maxBackupAmmo = 18,
}

weapons.sniper = {
    name = "Sniper",
    damage = 90,
    projectileSpeed = 0.5,
    projectilesPerShot = 1,
    fireRate = 0.8,

    spread = 0.2,
    shotSpread = 0.8,
    dashSpread = 0.1,
    movementSpread = 1,

    speedFactor = 0.9,
    canAim = true,
    isAuto = false,

    ammo = 5,
    maxAmmo = 5,
    reloadTime = 1.6,
    backupAmmo = 15,
    maxBackupAmmo = 15,
}

weapons.heavySniper = {
    name = "heavy Sniper",
    damage = 150,
    projectileSpeed = 0.7,
    projectilesPerShot = 1,
    fireRate = 0.3,

    spread = 0.02,
    shotSpread = 2,
    dashSpread = 0.3,
    movementSpread = 1,

    speedFactor = 0.7,
    canAim = true,
    isAuto = false,

    ammo = 3,
    maxAmmo = 3,
    reloadTime = 2.6,
    backupAmmo = 9,
    maxBackupAmmo = 9,
}

return weapons