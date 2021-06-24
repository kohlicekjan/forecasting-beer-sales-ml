import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from eli5.sklearn import PermutationImportance

def get_percentage_diff(previous, current):
    return 1 - (abs(previous - current)/max(previous, current))

def absolute_score(y_true, y_pred):
    return 1 - (np.sum(np.absolute(y_pred - y_true)) / np.sum(y_true))

def show_pred(y_test, y_pred, xlabel, ylabel):
    plt.figure(figsize=(8,6))
    plt.scatter(y_pred, y_test)
    plt.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'k--', lw=2)

    plt.xlabel(xlabel)
    plt.ylabel(ylabel)

    plt.show()


def show_feature_importances(model, X, y):
    model_name = type(model).__name__
    importances = None

    if hasattr(model, 'feature_importances_'):
        importances = model.feature_importances_       
    else:
        perm = PermutationImportance(model, cv = None, refit = False).fit(X, y)
        importances = perm.feature_importances_

    sorted_idx = importances.argsort()

    plt.figure(figsize=(8,6)) 
    plt.barh(X.columns[sorted_idx], importances[sorted_idx])
    plt.xlabel(f"{model_name} - Feature Importance")
    plt.show()

def reduce_mem_usage(df, ignoreCols=[], verbose=True):
    numerics = ['int16', 'int32', 'int64', 'float16', 'float32', 'float64']
    start_mem = df.memory_usage().sum() / 1024**2    
    for col in df.columns:    
        if col in ignoreCols:
            continue

        col_type = df[col].dtypes
        if col_type in numerics:
            c_min = df[col].min()
            c_max = df[col].max()
            if str(col_type)[:3] == 'int':
                if c_min > np.iinfo(np.int8).min and c_max < np.iinfo(np.int8).max:
                    df[col] = df[col].astype(np.int8)
                elif c_min > np.iinfo(np.int16).min and c_max < np.iinfo(np.int16).max:
                    df[col] = df[col].astype(np.int16)
                elif c_min > np.iinfo(np.int32).min and c_max < np.iinfo(np.int32).max:
                    df[col] = df[col].astype(np.int32)
                elif c_min > np.iinfo(np.int64).min and c_max < np.iinfo(np.int64).max:
                    df[col] = df[col].astype(np.int64)  
            else:
                if c_min > np.finfo(np.float16).min and c_max < np.finfo(np.float16).max:
                    df[col] = df[col].astype(np.float16)
                elif c_min > np.finfo(np.float32).min and c_max < np.finfo(np.float32).max:
                    df[col] = df[col].astype(np.float32)
                else:
                    df[col] = df[col].astype(np.float64)    
    end_mem = df.memory_usage().sum() / 1024**2
    if verbose: print('Mem. usage decreased to {:5.2f} Mb ({:.1f}% reduction)'.format(end_mem, 100 * (start_mem - end_mem) / start_mem))
    return df