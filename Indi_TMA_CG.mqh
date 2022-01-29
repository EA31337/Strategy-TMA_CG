//+------------------------------------------------------------------+
//|                                      Copyright 2016-2020, kenorb |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

// Defines
#define INDI_TMA_CG_PATH "indicators-other\\PriceBands"

// Indicator line identifiers used in the indicator.
enum ENUM_TMA_CG_MODE {
  TMA_CG_MN_BAND = 0,  // Middle band
  TMA_CG_UP_BAND,      // Upper band
  TMA_CG_LW_BAND,      // Lower band
  TMA_CG_DN_ARROW,     // Down arrow
  TMA_CG_UP_ARROW,     // Upper arrow
  TMA_CG_WU_BUFF,      // TMA WU buffer
  TMA_CG_WD_BUFF,      // TMA WD buffer
  FINAL_TMA_CG_MODE_ENTRY,
};

// Defines struct to store indicator parameter values.
// Structs.
struct Indi_TMA_CG_Params : IndicatorParams {
 public:
  bool CalculateTma;
  bool ReturnBars;
  int HalfLength;
  int AtrPeriod;
  double BandsDeviations;
  ENUM_APPLIED_PRICE MaAppliedPrice;
  ENUM_MA_METHOD MaMethod;
  int MaPeriod;
  int SignalDuration;
  bool Interpolate;
  bool AlertsOn;
  bool AlertsOnCurrent;
  bool AlertsOnHighLow;
  // Struct constructor.
  void Indi_TMA_CG_Params(bool _CalculateTma = false, bool _ReturnBars = false, int _HalfLength = 61,
                          int _AtrPeriod = 20, double _BandsDeviations = 2.8,
                          ENUM_APPLIED_PRICE _MaAppliedPrice = PRICE_WEIGHTED, ENUM_MA_METHOD _MaMethod = MODE_SMA,
                          int _MaPeriod = 1, int _SignalDuration = 3, bool _Interpolate = true, bool _AlertsOn = false,
                          bool _AlertsOnCurrent = false, bool _AlertsOnHighLow = false, int _shift = 0)
      : CalculateTma(_CalculateTma),
        ReturnBars(_ReturnBars),
        HalfLength(_HalfLength),
        AtrPeriod(_AtrPeriod),
        BandsDeviations(_BandsDeviations),
        MaAppliedPrice(_MaAppliedPrice),
        MaMethod(_MaMethod),
        MaPeriod(_MaPeriod),
        SignalDuration(_SignalDuration),
        Interpolate(_Interpolate),
        AlertsOn(_AlertsOn),
        AlertsOnCurrent(_AlertsOnCurrent),
        AlertsOnHighLow(_AlertsOnHighLow),
        IndicatorParams(INDI_CUSTOM, FINAL_TMA_CG_MODE_ENTRY, TYPE_DOUBLE) {
#ifdef __resource__
    custom_indi_name = "::" + INDI_TMA_CG_PATH + "\\TMA+CG_mladen_NRP";
#else
    custom_indi_name = "TMA+CG_mladen_NRP";
#endif
    SetDataSourceType(IDATA_ICUSTOM);
    SetShift(_shift);
  };
  Indi_TMA_CG_Params(Indi_TMA_CG_Params &_params, ENUM_TIMEFRAMES _tf) {
    this = _params;
    tf = _tf;
  }
};

/**
 * Implements indicator class.
 */
class Indi_TMA_CG : public Indicator<Indi_TMA_CG_Params> {
 protected:
  Indi_TMA_CG_Params params;

 public:
  /**
   * Class constructor.
   */
  Indi_TMA_CG(Indi_TMA_CG_Params &_p, IndicatorBase *_indi_src = NULL) : Indicator<Indi_TMA_CG_Params>(_p, _indi_src) {}
  Indi_TMA_CG(ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) : Indicator(INDI_CUSTOM, _tf){};

  /**
   * Returns the indicator's value.
   */
  IndicatorDataEntryValue GetEntryValue(int _mode = 0, int _shift = -1) {
    double _value = EMPTY_VALUE;
    int _ishift = _shift >= 0 ? _shift : iparams.GetShift();
    switch (params.idstype) {
      case IDATA_ICUSTOM:
        _value = iCustom(istate.handle, Get<string>(CHART_PARAM_SYMBOL), Get<ENUM_TIMEFRAMES>(CHART_PARAM_TF),
                         params.custom_indi_name, params.CalculateTma, params.ReturnBars, params.HalfLength,
                         params.AtrPeriod, params.BandsDeviations, params.MaAppliedPrice, params.MaMethod,
                         params.MaPeriod, params.SignalDuration, params.Interpolate, params.AlertsOn,
                         params.AlertsOnCurrent, params.AlertsOnHighLow, _mode, _shift);
        break;
      default:
        SetUserError(ERR_INVALID_PARAMETER);
        _value = EMPTY_VALUE;
        break;
    }
    return _value;
  }
};
