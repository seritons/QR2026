enum BizType {
  cafe,
  coffeeRoastery,
  pub,
  bar,
  restaurant,
  bistro,
  bakery,
  dessertShop,
  breakfastPlace,
  fastFood,
  seafood,
  steakhouse,
  pizza,
  burger,
  kebab,
  vegan,
}

extension BizTypeUi on BizType {
  String get label {
    switch (this) {
      case BizType.cafe: return 'Kafe';
      case BizType.coffeeRoastery: return 'Kahve Kavurma';
      case BizType.pub: return 'Pub';
      case BizType.bar: return 'Bar';
      case BizType.restaurant: return 'Restoran';
      case BizType.bistro: return 'Bistro';
      case BizType.bakery: return 'Fırın';
      case BizType.dessertShop: return 'Tatlıcı';
      case BizType.breakfastPlace: return 'Kahvaltı';
      case BizType.fastFood: return 'Fast Food';
      case BizType.seafood: return 'Balık / Deniz Ürünleri';
      case BizType.steakhouse: return 'Steakhouse';
      case BizType.pizza: return 'Pizza';
      case BizType.burger: return 'Burger';
      case BizType.kebab: return 'Kebap';
      case BizType.vegan: return 'Vegan';
    }
  }

  String get key {
    // DB’de meta.types içine yazacağımız string
    switch (this) {
      case BizType.cafe: return 'cafe';
      case BizType.coffeeRoastery: return 'coffee_roastery';
      case BizType.pub: return 'pub';
      case BizType.bar: return 'bar';
      case BizType.restaurant: return 'restaurant';
      case BizType.bistro: return 'bistro';
      case BizType.bakery: return 'bakery';
      case BizType.dessertShop: return 'dessert_shop';
      case BizType.breakfastPlace: return 'breakfast';
      case BizType.fastFood: return 'fast_food';
      case BizType.seafood: return 'seafood';
      case BizType.steakhouse: return 'steakhouse';
      case BizType.pizza: return 'pizza';
      case BizType.burger: return 'burger';
      case BizType.kebab: return 'kebab';
      case BizType.vegan: return 'vegan';
    }
  }
}

enum Offering {
  coffee,
  tea,
  breakfast,
  desserts,
  bakery,
  burgers,
  pizza,
  kebab,
  seafood,
  steak,
  veganOptions,
  alcohol,
  cocktails,
  wine,
  beer,
}

extension OfferingUi on Offering {
  String get label {
    switch (this) {
      case Offering.coffee: return 'Kahve';
      case Offering.tea: return 'Çay';
      case Offering.breakfast: return 'Kahvaltı';
      case Offering.desserts: return 'Tatlı';
      case Offering.bakery: return 'Fırın Ürünleri';
      case Offering.burgers: return 'Burger';
      case Offering.pizza: return 'Pizza';
      case Offering.kebab: return 'Kebap';
      case Offering.seafood: return 'Balık';
      case Offering.steak: return 'Et';
      case Offering.veganOptions: return 'Vegan Opsiyon';
      case Offering.alcohol: return 'Alkol';
      case Offering.cocktails: return 'Kokteyl';
      case Offering.wine: return 'Şarap';
      case Offering.beer: return 'Bira';
    }
  }

  String get key {
    switch (this) {
      case Offering.coffee: return 'coffee';
      case Offering.tea: return 'tea';
      case Offering.breakfast: return 'breakfast';
      case Offering.desserts: return 'desserts';
      case Offering.bakery: return 'bakery';
      case Offering.burgers: return 'burgers';
      case Offering.pizza: return 'pizza';
      case Offering.kebab: return 'kebab';
      case Offering.seafood: return 'seafood';
      case Offering.steak: return 'steak';
      case Offering.veganOptions: return 'vegan_options';
      case Offering.alcohol: return 'alcohol';
      case Offering.cocktails: return 'cocktails';
      case Offering.wine: return 'wine';
      case Offering.beer: return 'beer';
    }
  }
}

enum BizFeature {
  wifi,
  garden,
  terrace,
  liveMusic,
  workFriendly,
  powerOutlets,
  wheelchairAccessible,
  petFriendly,
  outdoorSeating,
  smokingArea,
  parking,
}

extension BizFeatureUi on BizFeature {
  String get label {
    switch (this) {
      case BizFeature.wifi: return 'Wi-Fi';
      case BizFeature.garden: return 'Bahçe';
      case BizFeature.terrace: return 'Teras';
      case BizFeature.liveMusic: return 'Canlı Müzik';
      case BizFeature.workFriendly: return 'Çalışma Alanı';
      case BizFeature.powerOutlets: return 'Priz';
      case BizFeature.wheelchairAccessible: return 'Engelli Erişimi';
      case BizFeature.petFriendly: return 'Evcil Dostu';
      case BizFeature.outdoorSeating: return 'Açık Oturma';
      case BizFeature.smokingArea: return 'Sigara Alanı';
      case BizFeature.parking: return 'Otopark';
    }
  }

  String get key {
    switch (this) {
      case BizFeature.wifi: return 'wifi';
      case BizFeature.garden: return 'garden';
      case BizFeature.terrace: return 'terrace';
      case BizFeature.liveMusic: return 'live_music';
      case BizFeature.workFriendly: return 'work_friendly';
      case BizFeature.powerOutlets: return 'power_outlets';
      case BizFeature.wheelchairAccessible: return 'wheelchair_accessible';
      case BizFeature.petFriendly: return 'pet_friendly';
      case BizFeature.outdoorSeating: return 'outdoor_seating';
      case BizFeature.smokingArea: return 'smoking_area';
      case BizFeature.parking: return 'parking';
    }
  }
}

enum BusinessStep { core, details }

class BusinessOnboardingState {
  final BusinessStep step;
  final bool isLoading;
  final String? error;

  const BusinessOnboardingState({
    this.step = BusinessStep.core,
    this.isLoading = false,
    this.error,
  });

  BusinessOnboardingState copyWith({
    BusinessStep? step,
    bool? isLoading,
    String? error,
  }) {
    return BusinessOnboardingState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
