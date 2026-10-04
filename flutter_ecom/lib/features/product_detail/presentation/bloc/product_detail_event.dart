import 'package:equatable/equatable.dart';

/// 商品详情事件
abstract class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object> get props => [];
}

/// 加载商品详情
class ProductDetailLoadEvent extends ProductDetailEvent {
  const ProductDetailLoadEvent(this.productId);

  final int productId;

  @override
  List<Object> get props => [productId];
}
