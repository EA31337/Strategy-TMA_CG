/**
 * @file
 * Implements TMA_CG strategy based on the TMA_CG indicator.
 */

// User input params.
INPUT_GROUP("TMA_CG strategy: strategy params");
INPUT float TMA_CG_LotSize = 0;                // Lot size
INPUT int TMA_CG_SignalOpenMethod = 0;         // Signal open method (-127-127)
INPUT float TMA_CG_SignalOpenLevel = 24.0;     // Signal open level (-49-49)
INPUT int TMA_CG_SignalOpenFilterMethod = 32;  // Signal open filter method (0-31)
INPUT int TMA_CG_SignalOpenFilterTime = 8;     // Signal open filter time (0-31)
INPUT int TMA_CG_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int TMA_CG_SignalCloseMethod = 0;        // Signal close method (-127-127)
INPUT int TMA_CG_SignalCloseFilter = 32;       // Signal close filter (-127-127)
INPUT float TMA_CG_SignalCloseLevel = 24.0;    // Signal close level (-49-49)
INPUT int TMA_CG_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float TMA_CG_PriceStopLevel = 0;         // Price stop level
INPUT int TMA_CG_TickFilterMethod = 1;         // Tick filter method
INPUT float TMA_CG_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short TMA_CG_Shift = 0;                  // Shift
INPUT float TMA_CG_OrderCloseLoss = 0;         // Order close loss
INPUT float TMA_CG_OrderCloseProfit = 0;       // Order close profit
INPUT int TMA_CG_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("TMA CG strategy: TMA CG indicator params");
INPUT int TMA_CG_Indi_TMA_CG_HalfLength = 61;                                  // Half length
INPUT int TMA_CG_Indi_TMA_CG_AtrPeriod = 6;                                    // ATR period
INPUT double TMA_CG_Indi_TMA_CG_BandsDeviations = 2.8;                         // Bands Deviations
INPUT ENUM_APPLIED_PRICE TMA_CG_Indi_TMA_CG_MA_AppliedPrice = PRICE_WEIGHTED;  // Applied price
INPUT ENUM_MA_METHOD TMA_CG_Indi_TMA_CG_MM = MODE_SMA;                         // MA Method
INPUT int TMA_CG_Indi_TMA_CG_Period = 1;                                       // MA Period
INPUT int TMA_CG_Indi_TMA_CG_SignalDuration = 3;                               // Signal duration
INPUT bool TMA_CG_Indi_TMA_CG_Interpolate = true;                              // Interpolate
INPUT int TMA_CG_Indi_TMA_CG_Shift = 0;                                        // Indicator Shift

// Includes.
#include <EA31337-classes/Strategy.mqh>

// Defines struct with default user strategy values.
struct Stg_TMA_CG_Params_Defaults : StgParams {
  Stg_TMA_CG_Params_Defaults()
      : StgParams(::TMA_CG_SignalOpenMethod, ::TMA_CG_SignalOpenFilterMethod, ::TMA_CG_SignalOpenLevel,
                  ::TMA_CG_SignalOpenBoostMethod, ::TMA_CG_SignalCloseMethod, ::TMA_CG_SignalCloseFilter, ::TMA_CG_SignalCloseLevel,
                  ::TMA_CG_PriceStopMethod, ::TMA_CG_PriceStopLevel, ::TMA_CG_TickFilterMethod, ::TMA_CG_MaxSpread, ::TMA_CG_Shift) {
    Set(STRAT_PARAM_OCL, TMA_CG_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, TMA_CG_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, TMA_CG_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, TMA_CG_SignalOpenFilterTime);
        }
} stg_tmacg_defaults;

// Defines struct to store indicator and strategy params.
struct Stg_TMA_CG_Params {
  StgParams sparams;

  // Struct constructors.
  Stg_TMA_CG_Params(StgParams &_sparams) : sparams(stg_tmacg_defaults) { sparams = _sparams; }
};

// Includes indicator class file.
#include "Indi_TMA_CG.mqh"

// Defines struct with default user indicator values.
struct Indi_TMA_CG_Params_Defaults : Indi_TMA_CG_Params {
  //Indi_TMA_CG_Params_Defaults() : Indi_TMA_CG_Params(::TMA_CG_Indi_TMA_CG_Shift) {}
} indi_tmacg_defaults;

// Loads pair specific param values.
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

  static Stg_TMA_CG *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_TMA_CG_Params _indi_params(indi_tmacg_defaults, _tf);
    StgParams _stg_params(stg_tmacg_defaults);
#ifdef __config__
      SetParamsByTf<Indi_TMA_CG_Params>(_indi_params, _tf, indi_tmacg_m1, indi_tmacg_m5, indi_tmacg_m15, indi_tmacg_m30,
                                        indi_tmacg_h1, indi_tmacg_h4, indi_tmacg_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_tmacg_m1, stg_tmacg_m5, stg_tmacg_m15, stg_tmacg_m30, stg_tmacg_h1,
                               stg_tmacg_h4, stg_tmacg_h8);
#endif
    // Initialize indicator.
    Indi_TMA_CG_Params tmacg_params(_indi_params);
    _stg_params.SetIndicator(new Indi_TMA_CG(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_TMA_CG(_stg_params, _tparams, _cparams, "TMA_CG");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indicator *_indi = GetIndicator();
    bool _result =
        _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) && _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 1);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi[_shift][0] < (50 - _level);
        _result &= _indi.IsIncreasing(1, 0, _shift);
        _result &= _indi.IsIncByPct(_level / 10, 0, _shift, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi[_shift][0] > (50 + _level);
        _result &= _indi.IsDecreasing(1, 0, _shift);
        _result &= _indi.IsDecByPct(_level / 10, 0, _shift, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }

};
