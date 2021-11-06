/**
 * @file
 * Implements TMA CG strategy based on the TMA CG indicator.
 */

// User input params.
INPUT string __TMA_CG_Parameters__ = "-- TMA CG strategy params --";  // >>> TMA CG <<<
INPUT int TMA_CG_SignalOpenMethod = 0;                                // Signal open method
INPUT int TMA_CG_SignalOpenFilterMethod = 32;                         // Signal open filter method
INPUT int TMA_CG_SignalOpenFilterTime = 3;                            // Signal open filter time
INPUT float TMA_CG_SignalOpenLevel = 0.0f;                            // Signal open level
INPUT int TMA_CG_SignalOpenBoostMethod = 0;                           // Signal open boost method
INPUT int TMA_CG_SignalCloseMethod = 0;                               // Signal close method
INPUT int TMA_CG_SignalCloseFilter = 32;                              // Signal close filter (-127-127)
INPUT float TMA_CG_SignalCloseLevel = 0.0f;                           // Signal close level
INPUT int TMA_CG_PriceStopMethod = 1;                                 // Price stop method (0-127)
INPUT float TMA_CG_PriceStopLevel = 2;                                // Price stop level
INPUT int TMA_CG_TickFilterMethod = 32;                               // Tick filter method (0-255)
INPUT float TMA_CG_MaxSpread = 4.0;                                   // Max spread to trade (in pips)
INPUT short TMA_CG_Shift = 0;            // Shift (relative to the current bar, 0 - default)
INPUT int TMA_CG_OrderCloseLoss = 80;    // Order close loss
INPUT int TMA_CG_OrderCloseProfit = 80;  // Order close profit
INPUT int TMA_CG_OrderCloseTime = -30;   // Order close time in mins (>0) or bars (<0)
INPUT string __TMA_CG_Indi_TMA_CG_Params__ =
    "-- TMA CG: TMA CG indicator params --";  // >>> TMA CG strategy: TMA CG indicator <<<
INPUT bool TMA_CG_Indi_TMA_CG_CalculateTma = false;
INPUT bool TMA_CG_Indi_TMA_CG_ReturnBars = false;
INPUT int TMA_CG_Indi_TMA_CG_HalfLength = 61;
INPUT int TMA_CG_Indi_TMA_CG_AtrPeriod = 20;
INPUT double TMA_CG_Indi_TMA_CG_BandsDeviations = 2.8;
INPUT ENUM_APPLIED_PRICE TMA_CG_Indi_TMA_CG_MaAppliedPrice = PRICE_WEIGHTED;
INPUT ENUM_MA_METHOD TMA_CG_Indi_TMA_CG_MaMethod = MODE_SMA;
INPUT int TMA_CG_Indi_TMA_CG_MaPeriod = 1;
INPUT int TMA_CG_Indi_TMA_CG_SignalDuration = 3;
INPUT bool TMA_CG_Indi_TMA_CG_Interpolate = true;
INPUT bool TMA_CG_Indi_TMA_CG_AlertsOn = false;
INPUT bool TMA_CG_Indi_TMA_CG_AlertsOnCurrent = false;
INPUT bool TMA_CG_Indi_TMA_CG_AlertsOnHighLow = false;
INPUT int TMA_CG_Indi_TMA_CG_Shift = 0;  // Shift (relative to the current bar, 0 - default)

// Includes.
#include "Indi_TMA_CG.mqh"

// Structs.

// Defines struct with default user indicator values.
struct Indi_TMA_CG_Params_Defaults : Indi_TMA_CG_Params {
  Indi_TMA_CG_Params_Defaults()
      : Indi_TMA_CG_Params(
            ::TMA_CG_Indi_TMA_CG_CalculateTma, ::TMA_CG_Indi_TMA_CG_ReturnBars, ::TMA_CG_Indi_TMA_CG_HalfLength,
            ::TMA_CG_Indi_TMA_CG_AtrPeriod, ::TMA_CG_Indi_TMA_CG_BandsDeviations, ::TMA_CG_Indi_TMA_CG_MaAppliedPrice,
            ::TMA_CG_Indi_TMA_CG_MaMethod, ::TMA_CG_Indi_TMA_CG_MaPeriod, ::TMA_CG_Indi_TMA_CG_SignalDuration,
            ::TMA_CG_Indi_TMA_CG_Interpolate, ::TMA_CG_Indi_TMA_CG_AlertsOn, ::TMA_CG_Indi_TMA_CG_AlertsOnCurrent,
            ::TMA_CG_Indi_TMA_CG_AlertsOnHighLow, ::TMA_CG_Indi_TMA_CG_Shift) {}
} stg_tmacg_indi_tmacg_defaults;

// Defines struct with default user strategy values.
struct Stg_TMA_CG_Params_Defaults : StgParams {
  Stg_TMA_CG_Params_Defaults()
      : StgParams(::TMA_CG_SignalOpenMethod, ::TMA_CG_SignalOpenFilterMethod, ::TMA_CG_SignalOpenLevel,
                  ::TMA_CG_SignalOpenBoostMethod, ::TMA_CG_SignalCloseMethod, ::TMA_CG_SignalCloseFilter,
                  ::TMA_CG_SignalCloseLevel, ::TMA_CG_PriceStopMethod, ::TMA_CG_PriceStopLevel,
                  ::TMA_CG_TickFilterMethod, ::TMA_CG_MaxSpread, ::TMA_CG_Shift) {
    Set(STRAT_PARAM_OCL, TMA_CG_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, TMA_CG_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, TMA_CG_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, TMA_CG_SignalOpenFilterTime);
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_TMA_CG : public Strategy {
 public:
  Stg_TMA_CG(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_TMA_CG *Init(ENUM_TIMEFRAMES _tf = NULL) {
    // Initialize strategy initial values.
    Stg_TMA_CG_Params_Defaults stg_tmacg_defaults;
    Indi_TMA_CG_Params _indi_params(stg_tmacg_indi_tmacg_defaults, _tf);
    StgParams _stg_params(stg_tmacg_defaults);
#ifdef __config__
    SetParamsByTf<Indi_TMA_CG_Params>(_indi_params, _tf, indi_tmacg_m1, indi_tmacg_m5, indi_tmacg_m15, indi_tmacg_m30,
                                      indi_tmacg_h1, indi_tmacg_h4, indi_tmacg_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_tmacg_m1, stg_tmacg_m5, stg_tmacg_m15, stg_tmacg_m30, stg_tmacg_h1,
                             stg_tmacg_h4, stg_tmacg_h8);
#endif
    // Initialize indicator.
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_TMA_CG(_stg_params, _tparams, _cparams, "TMA CG");
    _strat.SetIndicator(new Indi_TMA_CG(_indi_params));
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_TMA_CG *_indi = GetIndicator();
    int _ishift = _shift + ::TMA_CG_Indi_TMA_CG_Shift;
    bool _result = _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _ishift);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    Chart *_chart = (Chart *)_indi;
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi[_ishift][(int)TMA_CG_UP_ARROW] != 0;
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi[_ishift][(int)TMA_CG_DN_ARROW] != 0;
        break;
    }
    return _result;
  }

  /**
   * Checks if indicator entry values are valid.
   */
  virtual bool IsValidEntry(IndicatorDataEntry &_entry) {
    bool _result = true;
    _result &= _entry.values[(int)TMA_CG_MN_BAND] > 0;
    _result &= _entry.values[(int)TMA_CG_UP_BAND] > 0;
    _result &= _entry.values[(int)TMA_CG_LW_BAND] > 0;
    return _result;
  }
};
