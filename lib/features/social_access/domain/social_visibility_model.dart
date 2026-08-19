enum SocialVisibility {
  afterMatch,
  selective,
  always;

  String toDbString() {
    switch (this) {
      case SocialVisibility.afterMatch:
        return 'after_match';
      case SocialVisibility.selective:
        return 'selective';
      case SocialVisibility.always:
        return 'always';
    }
  }

  static SocialVisibility fromDbString(String? value) {
    switch (value) {
      case 'selective':
        return SocialVisibility.selective;
      case 'always':
        return SocialVisibility.always;
      case 'after_match':
      default:
        return SocialVisibility.afterMatch;
    }
  }

  String get label {
    switch (this) {
      case SocialVisibility.afterMatch:
        return 'Après match';
      case SocialVisibility.selective:
        return 'Choisir';
      case SocialVisibility.always:
        return 'Visible';
    }
  }

  String get description {
    switch (this) {
      case SocialVisibility.afterMatch:
        return 'Tes réseaux deviennent visibles uniquement quand vous vous êtes mutuellement likés.';
      case SocialVisibility.selective:
        return 'Sélectionne quels réseaux tu veux montrer.';
      case SocialVisibility.always:
        return 'Tes réseaux apparaissent directement sur ta carte.';
    }
  }
}
