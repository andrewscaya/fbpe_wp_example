<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'cms' );

/** MySQL database username */
define( 'DB_USER', 'cmsuser' );

/** MySQL database password */
define( 'DB_PASSWORD', 'testpass' );

/** MySQL hostname */
define( 'DB_HOST', 'localhost' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         '@?uiN~2}|*bJTY8,K1qN6)>P93;7wJx=~qgwk32k8zVclwRQ~i_YGxgvA^o}pdqB' );
define( 'SECURE_AUTH_KEY',  'wi?i)B=gl|K_&m-a:a!:k=8E@h^{}&;kCHlL^z^M,hsz0a!|zJM*t#dEAIUvv;m$' );
define( 'LOGGED_IN_KEY',    'd7| R Fi*){)31L$!h]HJ/da_uacIGTX_Wr.6BYF2l@cG9,+>=eZu3i)#m*RlmI$' );
define( 'NONCE_KEY',        '?.A6NX2ZIjk:^h(!Z9_)nIA+2I&*2Q9{#5i)n,K).)q:=@5fHxGy|k*j]RTyyRD{' );
define( 'AUTH_SALT',        'SY^u~jBf>JR+<-=-LL*57l;1o$Z4G,_pV47nF^/F=<L`~UU/gB}6bl)/C/XDi<Wa' );
define( 'SECURE_AUTH_SALT', 'qU#.pauHprNl()MQOB7J3KDC71Q~a WxXGx[wzp!>Tfjn>;C]]~t xU%+W3Yh9t&' );
define( 'LOGGED_IN_SALT',   'DmMbv DgOuJ+#ym5Nsm_@5aj<z@W1HL;@.)eXc!/oCwDE+5fS3zq&3EHxk$v5k+f' );
define( 'NONCE_SALT',       '!!S@)2~dU8#}94pYOf:ANN|Yd7z#B{s&D8l|tmz{HKN>1rOcsE.6vb<M(tzVQ,~s' );

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
